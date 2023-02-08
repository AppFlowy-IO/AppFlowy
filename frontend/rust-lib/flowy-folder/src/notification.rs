use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
const OBSERVABLE_CATEGORY: &str = "Workspace";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum FolderNotification {
    Unknown = 0,
    /// Trigger after creating a workspace
    DidCreateWorkspace = 1,
    /// Trigger after deleting a workspace
    DidDeleteWorkspace = 2,
    /// Trigger after updating a workspace
    DidUpdateWorkspace = 3,
    /// Trigger when the number of apps of the workspace is changed
    DidUpdateWorkspaceApps = 4,
    /// Trigger when the settings of the workspace are changed. The changes including the latest visiting view, etc
    DidUpdateWorkspaceSetting = 5,
    /// Trigger when the properties including rename,update description of the app are changed
    DidUpdateApp = 20,
    /// Trigger when the properties including rename,update description of the view are changed
    DidUpdateView = 30,
    /// Trigger after deleting the view
    DidDeleteView = 31,
    /// Trigger when restore the view from trash
    DidRestoreView = 32,
    /// Trigger after moving the view to trash
    DidMoveViewToTrash = 33,
    /// Trigger when the number of trash is changed
    DidUpdateTrash = 34,
}

impl std::default::Default for FolderNotification {
    fn default() -> Self {
        FolderNotification::Unknown
    }
}

impl std::convert::From<FolderNotification> for i32 {
    fn from(notification: FolderNotification) -> Self {
        notification as i32
    }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_notification(id: &str, ty: FolderNotification) -> NotificationBuilder {
    NotificationBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_anonymous_notification(ty: FolderNotification) -> NotificationBuilder {
    NotificationBuilder::new("", ty, OBSERVABLE_CATEGORY)
}
