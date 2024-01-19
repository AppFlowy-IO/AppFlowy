use std::collections::HashSet;
use std::sync::{Arc, Weak};

use collab::core::collab_state::SyncState;
use collab_folder::{
  Folder, SectionChange, SectionChangeReceiver, TrashSectionChange, View, ViewChange,
  ViewChangeReceiver,
};
use tokio_stream::wrappers::WatchStream;
use tokio_stream::StreamExt;
use tracing::{event, Level};

use lib_dispatch::prelude::af_spawn;

use crate::entities::{
  view_pb_with_child_views, view_pb_without_child_views, ChildViewUpdatePB, FolderSnapshotStatePB,
  FolderSyncStatePB, RepeatedTrashPB, RepeatedViewPB, ViewPB,
};
use crate::manager::{get_workspace_view_pbs, MutexFolder, WorkspaceOverviewListenerIdManager};
use crate::notification::{send_notification, FolderNotification};

/// Listen on the [ViewChange] after create/delete/update events happened
pub(crate) fn subscribe_folder_view_changed(
  mut rx: ViewChangeReceiver,
  weak_mutex_folder: &Weak<MutexFolder>,
  weak_workspace_overview_listener_id_manager: &Weak<WorkspaceOverviewListenerIdManager>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  let workspace_overview_listener_id_manager = weak_workspace_overview_listener_id_manager.clone();
  af_spawn(async move {
    while let Ok(value) = rx.recv().await {
      if let Some(folder) = weak_mutex_folder.upgrade() {
        tracing::trace!("Did receive view change: {:?}", value);
        let ffolder = folder.lock();
        if let Some(folder) = ffolder.as_ref() {
          match value {
            ViewChange::DidCreateView { view } => {
              if let Some(manager) = workspace_overview_listener_id_manager.upgrade() {
                notify_child_views_changed(
                  view_pb_without_child_views(Arc::new(view.clone())),
                  ChildViewChangeReason::Create,
                  manager,
                  folder,
                );
              }
              notify_parent_view_did_change(folder, vec![view.parent_view_id]);
            },
            ViewChange::DidDeleteView { views } => {
              for view in views {
                if let Some(manager) = workspace_overview_listener_id_manager.upgrade() {
                  notify_child_views_changed(
                    view_pb_without_child_views(view.clone()),
                    ChildViewChangeReason::Delete,
                    manager,
                    folder,
                  );
                }
              }
            },
            ViewChange::DidUpdate { view } => {
              notify_view_did_change(view.clone());
              if let Some(manager) = workspace_overview_listener_id_manager.upgrade() {
                notify_child_views_changed(
                  view_pb_without_child_views(Arc::new(view.clone())),
                  ChildViewChangeReason::Update,
                  manager,
                  folder,
                );
              }
              notify_parent_view_did_change(folder, vec![view.parent_view_id.clone()]);
            },
          };
        }
      }
    }
  });
}

pub(crate) fn subscribe_folder_snapshot_state_changed(
  workspace_id: String,
  weak_mutex_folder: &Weak<MutexFolder>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    if let Some(mutex_folder) = weak_mutex_folder.upgrade() {
      let stream = mutex_folder
        .lock()
        .as_ref()
        .map(|folder| folder.subscribe_snapshot_state());
      if let Some(mut state_stream) = stream {
        while let Some(snapshot_state) = state_stream.next().await {
          if let Some(new_snapshot_id) = snapshot_state.snapshot_id() {
            tracing::debug!("Did create folder remote snapshot: {}", new_snapshot_id);
            send_notification(
              &workspace_id,
              FolderNotification::DidUpdateFolderSnapshotState,
            )
            .payload(FolderSnapshotStatePB { new_snapshot_id })
            .send();
          }
        }
      }
    }
  });
}

pub(crate) fn subscribe_folder_sync_state_changed(
  workspace_id: String,
  mut folder_sync_state_rx: WatchStream<SyncState>,
  _weak_mutex_folder: &Weak<MutexFolder>,
) {
  af_spawn(async move {
    while let Some(state) = folder_sync_state_rx.next().await {
      send_notification(&workspace_id, FolderNotification::DidUpdateFolderSyncUpdate)
        .payload(FolderSyncStatePB::from(state))
        .send();
    }
  });
}

/// Listen on the [TrashChange]s and notify the frontend some views were changed.
pub(crate) fn subscribe_folder_trash_changed(
  mut rx: SectionChangeReceiver,
  weak_mutex_folder: &Weak<MutexFolder>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    while let Ok(value) = rx.recv().await {
      if let Some(folder) = weak_mutex_folder.upgrade() {
        let mut unique_ids = HashSet::new();
        tracing::trace!("Did receive trash change: {:?}", value);

        match value {
          SectionChange::Trash(change) => {
            let ids = match change {
              TrashSectionChange::TrashItemAdded { ids } => ids,
              TrashSectionChange::TrashItemRemoved { ids } => ids,
            };
            if let Some(folder) = folder.lock().as_ref() {
              let views = folder.views.get_views(&ids);
              for view in views {
                unique_ids.insert(view.parent_view_id.clone());
              }

              let repeated_trash: RepeatedTrashPB = folder.get_all_trash().into();
              send_notification("trash", FolderNotification::DidUpdateTrash)
                .payload(repeated_trash)
                .send();

              let parent_view_ids = unique_ids.into_iter().collect();
              notify_parent_view_did_change(folder, parent_view_ids);
            }
          },
        }
      }
    }
  });
}

/// Notify the the list of parent view ids that its child views were changed.
#[tracing::instrument(level = "debug", skip(folder, parent_view_ids))]
pub(crate) fn notify_parent_view_did_change<T: AsRef<str>>(
  folder: &Folder,
  parent_view_ids: Vec<T>,
) -> Option<()> {
  let workspace_id = folder.get_workspace_id();
  let trash_ids = folder
    .get_all_trash()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  for parent_view_id in parent_view_ids {
    let parent_view_id = parent_view_id.as_ref();

    // if the view's parent id equal to workspace id. Then it will fetch the current
    // workspace views. Because the the workspace is not a view stored in the views map.
    if parent_view_id == workspace_id {
      notify_did_update_workspace(&workspace_id, folder)
    } else {
      // Parent view can contain a list of child views. Currently, only get the first level
      // child views.
      let parent_view = folder.views.get_view(parent_view_id)?;
      let mut child_views = folder.views.get_views_belong_to(parent_view_id);
      child_views.retain(|view| !trash_ids.contains(&view.id));
      event!(Level::DEBUG, child_views_count = child_views.len());

      // Post the notification
      let parent_view_pb = view_pb_with_child_views(parent_view, child_views);
      send_notification(parent_view_id, FolderNotification::DidUpdateView)
        .payload(parent_view_pb)
        .send();
    }
  }

  None
}

pub(crate) fn notify_did_update_workspace(workspace_id: &str, folder: &Folder) {
  let repeated_view: RepeatedViewPB = get_workspace_view_pbs(workspace_id, folder).into();
  tracing::trace!("Did update workspace views: {:?}", repeated_view);
  send_notification(workspace_id, FolderNotification::DidUpdateWorkspaceViews)
    .payload(repeated_view)
    .send();
}

fn notify_view_did_change(view: View) -> Option<()> {
  let view_pb = view_pb_without_child_views(Arc::new(view.clone()));
  send_notification(&view.id, FolderNotification::DidUpdateView)
    .payload(view_pb)
    .send();
  None
}

pub enum ChildViewChangeReason {
  Create,
  Delete,
  Update,
}

/// Notify the the list of parent view ids that its child views were changed.
#[tracing::instrument(level = "debug", skip_all)]
pub(crate) fn notify_child_views_changed(
  view_pb: ViewPB,
  reason: ChildViewChangeReason,
  workspace_overview_listener_id_manager: Arc<WorkspaceOverviewListenerIdManager>,
  folder: &Folder,
) -> Option<()> {
  let parent_view_id = view_pb.parent_view_id.clone();
  let mut payload = ChildViewUpdatePB {
    parent_view_id: view_pb.parent_view_id.clone(),
    ..Default::default()
  };

  match reason {
    ChildViewChangeReason::Create => {
      payload.create_child_views.push(view_pb.clone());
    },
    ChildViewChangeReason::Delete => {
      payload.delete_child_views.push(view_pb.id.clone());
    },
    ChildViewChangeReason::Update => {
      payload.update_child_views.push(view_pb.clone());
    },
  }

  send_notification(&parent_view_id, FolderNotification::DidUpdateChildViews)
    .payload(payload)
    .send();

  let workspace_overview_listener_id_manager = workspace_overview_listener_id_manager.clone();
  //let workspace_id = folder.get_workspace_id();
  if let Some(id) = contains_child_view_id_in_overview_listener(
    &view_pb,
    &workspace_overview_listener_id_manager.view_ids.write()[..],
    folder,
  ) {
    let mut payload = ChildViewUpdatePB {
      parent_view_id: id.clone(),
      ..Default::default()
    };

    match reason {
      ChildViewChangeReason::Create => {
        payload.create_child_views.push(view_pb.clone());
      },
      ChildViewChangeReason::Delete => {
        payload.delete_child_views.push(view_pb.id.clone());
      },
      ChildViewChangeReason::Update => {
        payload.update_child_views.push(view_pb.clone());
      },
    }

    tracing::trace!(
      "Did receive workspace overview change: {:?}",
      &payload.delete_child_views
    );
    send_notification(
      &id,
      FolderNotification::DidUpdateWorkspaceOverviewChildViews,
    )
    .payload(payload)
    .send();
  }

  Some(())
}

pub fn contains_child_view_id_in_overview_listener(
  view_pb: &ViewPB,
  view_ids: &[String],
  folder: &Folder,
) -> Option<String> {
  if &view_pb.parent_view_id == &folder.get_workspace_id()
    || &view_pb.id == &folder.get_workspace_id()
  {
    return None;
  }

  if view_ids.contains(&view_pb.parent_view_id) {
    return Some(view_pb.parent_view_id.clone());
  }

  let view = folder.views.get_view(&view_pb.parent_view_id)?;
  let view_pb = view_pb_without_child_views(view);
  contains_child_view_id_in_overview_listener(&view_pb, view_ids, folder)
}
