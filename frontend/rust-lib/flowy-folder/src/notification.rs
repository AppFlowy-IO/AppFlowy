use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
const OBSERVABLE_CATEGORY: &str = "Workspace";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum FolderNotification {
    Unknown = 0,
    UserCreateWorkspace = 10,
    UserDeleteWorkspace = 11,
    WorkspaceUpdated = 12,
    WorkspaceListUpdated = 13,
    WorkspaceAppsChanged = 14,
    WorkspaceSetting = 15,
    AppUpdated = 21,
    ViewUpdated = 31,
    ViewDeleted = 32,
    ViewRestored = 33,
    ViewMoveToTrash = 34,
    UserUnauthorized = 100,
    TrashUpdated = 1000,
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
