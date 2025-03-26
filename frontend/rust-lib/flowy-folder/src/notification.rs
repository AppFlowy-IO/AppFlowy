use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
use lib_dispatch::prelude::ToBytes;
use num_derive::{FromPrimitive, ToPrimitive};

const WORKSPACE_OBSERVABLE_SOURCE: &str = "Workspace";
const FOLDER_OBSERVABLE_SOURCE: &str = "Folder";

#[derive(ProtoBuf_Enum, Debug, Default, FromPrimitive, ToPrimitive, Clone, Copy)]
pub enum FolderNotification {
  #[default]
  Unknown = 0,

  // ------------------------------- Start of Workspace -------------------------------
  /// Trigger after creating a workspace
  DidCreateWorkspace = 1,
  /// Trigger after updating a workspace
  DidUpdateWorkspace = 2,
  DidUpdateWorkspaceViews = 3,
  /// Trigger when the settings of the workspace are changed. The changes including the latest visiting view, etc
  DidUpdateWorkspaceSetting = 4,
  // ------------------------------- End of Workspace -------------------------------

  // The view notifications are deprecated from version 0.8.9, please use the page notifications instead.
  /// ------------------------------- Start of View -------------------------------
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
  // ------------------------------- End of View -------------------------------

  // ------------------------------- Start of Page -------------------------------
  DidCreatePage = 60,
  DidUpdatePage = 61,
  DidDeletePage = 62,
  DidMovePageToTrash = 63,
  DidRestorePageFromTrash = 64,
  DidDuplicatePage = 65,
  DidMovePage = 66,
  DidFavoritePage = 67,
  DidUnfavoritePage = 68,
  DidUpdateFolderPages = 69,
  DidUpdateFavoritePages = 70,
  DidUpdateTrashPages = 71,
  DidUpdateRecentPages = 72,
  DidSyncPendingOperations = 73,
  // ------------------------------- End of Page -------------------------------
}

impl From<FolderNotification> for i32 {
  fn from(notification: FolderNotification) -> Self {
    notification as i32
  }
}

impl From<i32> for FolderNotification {
  fn from(value: i32) -> Self {
    num_traits::FromPrimitive::from_i32(value).unwrap_or(FolderNotification::Unknown)
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn workspace_notification_builder(
  id: &str,
  ty: FolderNotification,
) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, WORKSPACE_OBSERVABLE_SOURCE)
}

pub(crate) fn send_current_workspace_notification<T: ToBytes>(ty: FolderNotification, payload: T) {
  workspace_notification_builder(WORKSPACE_OBSERVABLE_SOURCE, ty)
    .payload(payload)
    .send();
}

#[tracing::instrument(level = "trace")]
pub(crate) fn folder_notification_builder(id: &str, ty: FolderNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, FOLDER_OBSERVABLE_SOURCE)
}

pub trait FolderNotificationPayload: ToBytes {
  fn workspace_id(&self) -> &str;
}

pub(crate) fn send_folder_notification_with_payload<T: FolderNotificationPayload>(
  id: &str,
  ty: FolderNotification,
  payload: T,
) {
  folder_notification_builder(id, ty).payload(payload).send();
}

pub(crate) fn send_folder_notification(id: &str, ty: FolderNotification) {
  folder_notification_builder(id, ty).send();
}
