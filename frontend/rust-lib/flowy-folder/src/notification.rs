use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
use lib_dispatch::prelude::ToBytes;

const FOLDER_OBSERVABLE_SOURCE: &str = "Workspace";

#[derive(ProtoBuf_Enum, Debug, Default)]
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
}

impl std::convert::From<FolderNotification> for i32 {
  fn from(notification: FolderNotification) -> Self {
    notification as i32
  }
}

impl std::convert::From<i32> for FolderNotification {
  fn from(value: i32) -> Self {
    match value {
      1 => FolderNotification::DidCreateWorkspace,
      2 => FolderNotification::DidUpdateWorkspace,
      3 => FolderNotification::DidUpdateWorkspaceViews,
      4 => FolderNotification::DidUpdateWorkspaceSetting,
      10 => FolderNotification::DidUpdateView,
      11 => FolderNotification::DidUpdateChildViews,
      12 => FolderNotification::DidDeleteView,
      13 => FolderNotification::DidRestoreView,
      14 => FolderNotification::DidMoveViewToTrash,
      15 => FolderNotification::DidUpdateTrash,
      16 => FolderNotification::DidUpdateFolderSnapshotState,
      17 => FolderNotification::DidUpdateFolderSyncUpdate,
      36 => FolderNotification::DidFavoriteView,
      37 => FolderNotification::DidUnfavoriteView,
      38 => FolderNotification::DidUpdateRecentViews,
      39 => FolderNotification::DidUpdateSectionViews,
      _ => FolderNotification::Unknown,
    }
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_notification(id: &str, ty: FolderNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, FOLDER_OBSERVABLE_SOURCE)
}

/// The [CURRENT_WORKSPACE] represents as the current workspace that opened by the
/// user. Only one workspace can be opened at a time.
const CURRENT_WORKSPACE: &str = "current-workspace";
pub(crate) fn send_current_workspace_notification<T: ToBytes>(ty: FolderNotification, payload: T) {
  send_notification(CURRENT_WORKSPACE, ty)
    .payload(payload)
    .send();
}
