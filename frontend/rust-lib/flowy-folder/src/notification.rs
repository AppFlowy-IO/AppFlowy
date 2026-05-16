use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
use num_enum::{IntoPrimitive, TryFromPrimitive};
use tracing::trace;

const FOLDER_OBSERVABLE_SOURCE: &str = "Workspace";

#[derive(ProtoBuf_Enum, Debug, Default, IntoPrimitive, TryFromPrimitive)]
#[repr(i32)]
pub enum FolderNotification {
  #[default]
  Unknown = 0,
  /// Trigger after creating a workspace
  DidCreateWorkspace = 1,
  /// Trigger after updating a workspace
  DidUpdateWorkspace = 2,

  DidUpdateWorkspaceViews = 3,
  /// Trigger when the settings of the workspace are changed. The changes including the latest visiting view, etc
  DidUpdateWorkspaceSetting = 4,

  DidUpdateView = 10,
  DidUpdateChildViews = 11,
  /// Trigger after deleting the view
  DidDeleteView = 12,
  /// Trigger when restore the view from trash
  DidRestoreView = 13,
  /// Trigger after moving the view to trash
  DidMoveViewToTrash = 14,
  /// Trigger when the number of trash is changed
  DidUpdateTrash = 15,
  DidUpdateFolderSnapshotState = 16,
  DidUpdateFolderSyncUpdate = 17,

  DidFavoriteView = 36,
  DidUnfavoriteView = 37,

  DidUpdateRecentViews = 38,

  /// Trigger when the ROOT views (the first level) in section are updated
  DidUpdateSectionViews = 39,

  DidUpdateSharedViews = 40,
  DidUpdateSharedUsers = 41,
}

#[tracing::instrument(level = "trace", skip_all)]
pub(crate) fn folder_notification_builder<T: ToString>(
  id: T,
  ty: FolderNotification,
) -> NotificationBuilder {
  let id = id.to_string();
  trace!("folder_notification_builder: id = {id}, ty = {ty:?}");
  NotificationBuilder::new(&id, ty, FOLDER_OBSERVABLE_SOURCE)
}
