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
  let weak_workspace_overview_manager = weak_workspace_overview_listener_id_manager.clone();
  af_spawn(async move {
    while let Ok(value) = rx.recv().await {
      if let Some(folder) = weak_mutex_folder.upgrade() {
        if let Some(folder) = folder.lock().as_ref() {
          if let Some(workspace_overview_manager) = weak_workspace_overview_manager.upgrade() {
            tracing::trace!("Did receive view change: {:?}", value);
            match value {
              ViewChange::DidCreateView { view } => {
                let view_pb = view_pb_without_child_views(Arc::new(view.clone()));
                let child_view_update_payload = generate_child_view_update_payload(
                  view_pb.clone(),
                  ChildViewChangeReason::Create,
                );
                notify_child_views_changed(child_view_update_payload.clone());
                notify_workspace_overview_child_views_changed(
                  view_pb,
                  child_view_update_payload,
                  workspace_overview_manager.as_ref(),
                  folder,
                );
                notify_parent_view_did_change(folder, vec![view.parent_view_id]);
              },
              ViewChange::DidDeleteView { views } => {
                for view in views {
                  let view_pb = view_pb_without_child_views(view.clone());
                  let child_view_update_payload = generate_child_view_update_payload(
                    view_pb.clone(),
                    ChildViewChangeReason::Delete,
                  );
                  notify_child_views_changed(child_view_update_payload.clone());
                  notify_workspace_overview_child_views_changed(
                    view_pb,
                    child_view_update_payload,
                    workspace_overview_manager.as_ref(),
                    folder,
                  );
                }
              },
              ViewChange::DidUpdate { view } => {
                let view_pb = view_pb_without_child_views(Arc::new(view.clone()));
                let child_view_update_payload = generate_child_view_update_payload(
                  view_pb.clone(),
                  ChildViewChangeReason::Update,
                );
                notify_view_did_change(view.clone());
                notify_workspace_overview_view_did_change(
                  view.clone(),
                  workspace_overview_manager.as_ref(),
                );
                notify_child_views_changed(child_view_update_payload.clone());
                notify_workspace_overview_child_views_changed(
                  view_pb.clone(),
                  child_view_update_payload,
                  workspace_overview_manager.as_ref(),
                  folder,
                );
                notify_parent_view_did_change(folder, vec![view.parent_view_id]);
              },
            };
          }
        }
      }
    }
  });
}

pub(crate) fn generate_child_view_update_payload(
  view_pb: ViewPB,
  reason: ChildViewChangeReason,
) -> ChildViewUpdatePB {
  let mut payload = ChildViewUpdatePB {
    parent_view_id: view_pb.parent_view_id.clone(),
    ..Default::default()
  };

  match reason {
    ChildViewChangeReason::Create => {
      payload.create_child_views.push(view_pb);
    },
    ChildViewChangeReason::Delete => {
      payload.delete_child_views.push(view_pb.id);
    },
    ChildViewChangeReason::Update => {
      payload.update_child_views.push(view_pb);
    },
  }

  payload
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
  let view_id = view.id.clone();
  let view_pb = view_pb_without_child_views(view);
  send_notification(&view_id, FolderNotification::DidUpdateView)
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
pub(crate) fn notify_child_views_changed(payload: ChildViewUpdatePB) {
  let parent_view_id = payload.parent_view_id.clone();
  tracing::trace!("Did update child views: {:?}", payload);
  send_notification(&parent_view_id, FolderNotification::DidUpdateChildViews)
    .payload(payload)
    .send();
}

/// Notify the parent view of workspace overview block component
#[tracing::instrument(level = "debug", skip_all)]
pub(crate) fn notify_workspace_overview_view_did_change(
  view: View,
  workspace_overview_manager: &WorkspaceOverviewListenerIdManager,
) {
  if let Ok(res) = workspace_overview_manager.contains(&view.id) {
    if res {
      tracing::trace!("Did update workspace overview parent view: {:?}", view);
      let view_pb = view_pb_without_child_views(Arc::new(view.clone()));
      send_notification(
        &view.id,
        FolderNotification::DidUpdateWorkspaceOverviewParentView,
      )
      .payload(view_pb)
      .send();
    }
  }
}

/// Notify the parent view IDs listed in the workspace overview that their child views were changed
/// trigger events: [move, import]
#[tracing::instrument(level = "debug", skip_all)]
pub(crate) fn notify_workspace_overview_parent_view_did_change<T: AsRef<str>>(
  folder: &Folder,
  weak_workspace_overview_manager: &Weak<WorkspaceOverviewListenerIdManager>,
  parent_view_ids: Vec<T>,
) -> Option<()> {
  let workspace_overview_manager = weak_workspace_overview_manager.clone().upgrade()?;
  let listener_ids = workspace_overview_manager.get_view_ids()?;
  tracing::trace!("workspace overview listener ids: {:?}", listener_ids);

  if !listener_ids.is_empty() {
    let workspace_id = folder.get_workspace_id();
    let trash_ids = folder
      .get_all_trash()
      .into_iter()
      .map(|trash| trash.id)
      .collect::<Vec<String>>();

    if let Some(parent_view_id) = parent_view_ids.into_iter().next() {
      let parent_view_id = parent_view_id.as_ref();

      // if the view's parent id equal to workspace id. Then it will fetch the current
      // workspace views. Because the the workspace is not a view stored in the views map.
      if parent_view_id == workspace_id {
        notify_did_update_workspace(&workspace_id, folder)
      } else {
        let parent_view = folder.views.get_view(parent_view_id)?;
        let mut child_views = folder.views.get_views_belong_to(parent_view_id);
        child_views.retain(|view| !trash_ids.contains(&view.id));

        event!(Level::DEBUG, child_views_count = child_views.len());

        let parent_view_pb = view_pb_with_child_views(parent_view, child_views);

        // starts to check from the parent of the `parent_view_id`
        let mut view_ids: Vec<String> = Vec::new();
        contains_parent_view_in_overview_listener(
          &parent_view_pb,
          &listener_ids,
          &folder.get_workspace_id(),
          folder,
          &mut view_ids,
        );

        // `view_ids` only contains ids that are parent to the `parent_view_id`,
        // need to explicitly check the `parent_view_id` whether to send the notification
        if listener_ids.contains(parent_view_id) {
          send_notification(
            parent_view_id,
            FolderNotification::DidUpdateWorkspaceOverviewChildViews,
          )
          .payload(parent_view_pb.clone())
          .send();
        }

        for id in &view_ids {
          send_notification(id, FolderNotification::DidUpdateWorkspaceOverviewChildViews)
            .payload(parent_view_pb.clone())
            .send();
        }
      }
      return Some(());
    }
  }

  None
}

/// Notify the parent view IDs listed in the workspace overview that their child views were changed
/// trigger events: [new, update, delete]
#[tracing::instrument(level = "debug", skip_all)]
pub(crate) fn notify_workspace_overview_child_views_changed(
  view_pb: ViewPB,
  payload: ChildViewUpdatePB,
  workspace_overview_manager: &WorkspaceOverviewListenerIdManager,
  folder: &Folder,
) -> Option<()> {
  let listener_ids = workspace_overview_manager.get_view_ids()?;
  tracing::trace!("workspace overview listener ids: {:?}", listener_ids);
  if listener_ids.is_empty() {
    return None;
  }

  let mut view_ids: Vec<String> = Vec::new();
  contains_parent_view_in_overview_listener(
    &view_pb,
    &listener_ids,
    &folder.get_workspace_id(),
    folder,
    &mut view_ids,
  );

  // Retain the parent view ID of the updated child views to retrieve specific view key-value pairs
  // from the view map. This enables checking against the particular view's child views in the frontend and
  // constructing the workspace overview block efficiently, avoiding unnecessary rebuilds.
  tracing::trace!("Did update workspace overview child views: {:?}", payload);
  for id in &view_ids {
    send_notification(id, FolderNotification::DidUpdateWorkspaceOverviewChildViews)
      .payload(payload.clone())
      .send();
  }

  Some(())
}

pub(crate) fn contains_parent_view_in_overview_listener(
  view_pb: &ViewPB,
  listener_ids: &HashSet<String>,
  workspace_id: &str,
  folder: &Folder,
  view_ids: &mut Vec<String>,
) {
  let parent_view_id = &view_pb.parent_view_id;

  if parent_view_id != workspace_id || view_pb.id != workspace_id {
    if listener_ids.contains(parent_view_id) {
      view_ids.push(parent_view_id.clone());
    }

    if let Some(view) = folder.views.get_view(parent_view_id) {
      let view_pb = view_pb_without_child_views(view);
      contains_parent_view_in_overview_listener(
        &view_pb,
        listener_ids,
        workspace_id,
        folder,
        view_ids,
      )
    }
  }
}
