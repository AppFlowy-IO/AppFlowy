use crate::entities::{
  view_pb_with_child_views, view_pb_without_child_views, ChildViewUpdatePB, FolderSnapshotStatePB,
  FolderSyncStatePB, RepeatedTrashPB, RepeatedViewPB, SectionViewsPB, ViewPB, ViewSectionPB,
};
use crate::manager::{
  get_workspace_private_view_pbs, get_workspace_public_view_pbs, FolderUser, MutexFolder,
};
use crate::notification::{send_notification, FolderNotification};
use collab::core::collab_state::SyncState;
use collab_folder::{
  Folder, SectionChange, SectionChangeReceiver, TrashSectionChange, View, ViewChange,
  ViewChangeReceiver,
};
use lib_dispatch::prelude::af_spawn;
use std::collections::HashSet;
use std::sync::{Arc, Weak};
use tokio_stream::wrappers::WatchStream;
use tokio_stream::StreamExt;
use tracing::{event, trace, Level};

/// Listen on the [ViewChange] after create/delete/update events happened
pub(crate) fn subscribe_folder_view_changed(
  workspace_id: String,
  mut rx: ViewChangeReceiver,
  weak_mutex_folder: &Weak<MutexFolder>,
  user: Weak<dyn FolderUser>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    while let Ok(value) = rx.recv().await {
      if let Some(user) = user.upgrade() {
        if let Ok(actual_workspace_id) = user.workspace_id() {
          if actual_workspace_id != workspace_id {
            trace!("Did break the loop when the workspace id is not matched");
            // break the loop when the workspace id is not matched.
            break;
          }
        }
      }

      if let Some(folder) = weak_mutex_folder.upgrade() {
        tracing::trace!("Did receive view change: {:?}", value);
        match value {
          ViewChange::DidCreateView { view } => {
            notify_child_views_changed(
              view_pb_without_child_views(view.clone()),
              ChildViewChangeReason::Create,
            );
            notify_parent_view_did_change(&workspace_id, folder.clone(), vec![view.parent_view_id]);
          },
          ViewChange::DidDeleteView { views } => {
            for view in views {
              notify_child_views_changed(
                view_pb_without_child_views(view.as_ref().clone()),
                ChildViewChangeReason::Delete,
              );
            }
          },
          ViewChange::DidUpdate { view } => {
            notify_view_did_change(view.clone());
            notify_child_views_changed(
              view_pb_without_child_views(view.clone()),
              ChildViewChangeReason::Update,
            );
            notify_parent_view_did_change(
              &workspace_id,
              folder.clone(),
              vec![view.parent_view_id.clone()],
            );
          },
        };
      }
    }
  });
}

pub(crate) fn subscribe_folder_snapshot_state_changed(
  workspace_id: String,
  weak_mutex_folder: &Weak<MutexFolder>,
  user: Weak<dyn FolderUser>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    if let Some(mutex_folder) = weak_mutex_folder.upgrade() {
      let stream = mutex_folder
        .read()
        .as_ref()
        .map(|folder| folder.subscribe_snapshot_state());
      if let Some(mut state_stream) = stream {
        while let Some(snapshot_state) = state_stream.next().await {
          if let Some(user) = user.upgrade() {
            if let Ok(actual_workspace_id) = user.workspace_id() {
              if actual_workspace_id != workspace_id {
                // break the loop when the workspace id is not matched.
                break;
              }
            }
          }
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
  user: Weak<dyn FolderUser>,
) {
  af_spawn(async move {
    while let Some(state) = folder_sync_state_rx.next().await {
      if let Some(user) = user.upgrade() {
        if let Ok(actual_workspace_id) = user.workspace_id() {
          if actual_workspace_id != workspace_id {
            // break the loop when the workspace id is not matched.
            break;
          }
        }
      }

      send_notification(&workspace_id, FolderNotification::DidUpdateFolderSyncUpdate)
        .payload(FolderSyncStatePB::from(state))
        .send();
    }
  });
}

/// Listen on the [TrashChange]s and notify the frontend some views were changed.
pub(crate) fn subscribe_folder_trash_changed(
  workspace_id: String,
  mut rx: SectionChangeReceiver,
  weak_mutex_folder: &Weak<MutexFolder>,
  user: Weak<dyn FolderUser>,
) {
  let weak_mutex_folder = weak_mutex_folder.clone();
  af_spawn(async move {
    while let Ok(value) = rx.recv().await {
      if let Some(user) = user.upgrade() {
        if let Ok(actual_workspace_id) = user.workspace_id() {
          if actual_workspace_id != workspace_id {
            // break the loop when the workspace id is not matched.
            break;
          }
        }
      }

      if let Some(folder) = weak_mutex_folder.upgrade() {
        let mut unique_ids = HashSet::new();
        tracing::trace!("Did receive trash change: {:?}", value);

        match value {
          SectionChange::Trash(change) => {
            let ids = match change {
              TrashSectionChange::TrashItemAdded { ids } => ids,
              TrashSectionChange::TrashItemRemoved { ids } => ids,
            };
            if let Some(folder) = folder.read().as_ref() {
              let views = folder.get_views(&ids);
              for view in views {
                unique_ids.insert(view.parent_view_id.clone());
              }

              let repeated_trash: RepeatedTrashPB = folder.get_my_trash_info().into();
              send_notification("trash", FolderNotification::DidUpdateTrash)
                .payload(repeated_trash)
                .send();
            }

            let parent_view_ids = unique_ids.into_iter().collect();
            notify_parent_view_did_change(&workspace_id, folder.clone(), parent_view_ids);
          },
        }
      }
    }
  });
}

/// Notify the list of parent view ids that its child views were changed.
#[tracing::instrument(level = "debug", skip(folder, parent_view_ids))]
pub(crate) fn notify_parent_view_did_change<T: AsRef<str>>(
  workspace_id: &str,
  folder: Arc<MutexFolder>,
  parent_view_ids: Vec<T>,
) -> Option<()> {
  let folder = folder.read();
  let folder = folder.as_ref()?;
  let trash_ids = folder
    .get_all_trash_sections()
    .into_iter()
    .map(|trash| trash.id)
    .collect::<Vec<String>>();

  for parent_view_id in parent_view_ids {
    let parent_view_id = parent_view_id.as_ref();

    // if the view's parent id equal to workspace id. Then it will fetch the current
    // workspace views. Because the workspace is not a view stored in the views map.
    if parent_view_id == workspace_id {
      notify_did_update_workspace(workspace_id, folder);
      notify_did_update_section_views(workspace_id, folder);
    } else {
      // Parent view can contain a list of child views. Currently, only get the first level
      // child views.
      let parent_view = folder.get_view(parent_view_id)?;
      let mut child_views = folder.get_views_belong_to(parent_view_id);
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

pub(crate) fn notify_did_update_section_views(workspace_id: &str, folder: &Folder) {
  let public_views = get_workspace_public_view_pbs(workspace_id, folder);
  let private_views = get_workspace_private_view_pbs(workspace_id, folder);
  tracing::trace!(
    "Did update section views: public len = {}, private len = {}",
    public_views.len(),
    private_views.len()
  );

  // Notify the public views
  send_notification(workspace_id, FolderNotification::DidUpdateSectionViews)
    .payload(SectionViewsPB {
      section: ViewSectionPB::Public,
      views: public_views,
    })
    .send();

  // Notify the private views
  send_notification(workspace_id, FolderNotification::DidUpdateSectionViews)
    .payload(SectionViewsPB {
      section: ViewSectionPB::Private,
      views: private_views,
    })
    .send();
}

pub(crate) fn notify_did_update_workspace(workspace_id: &str, folder: &Folder) {
  let repeated_view: RepeatedViewPB = get_workspace_public_view_pbs(workspace_id, folder).into();
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

/// Notify the list of parent view ids that its child views were changed.
#[tracing::instrument(level = "debug", skip_all)]
pub(crate) fn notify_child_views_changed(view_pb: ViewPB, reason: ChildViewChangeReason) {
  let parent_view_id = view_pb.parent_view_id.clone();
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

  send_notification(&parent_view_id, FolderNotification::DidUpdateChildViews)
    .payload(payload)
    .send();
}
