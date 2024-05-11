use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

use crate::entities::AuthStateChangedPB;

const USER_OBSERVABLE_SOURCE: &str = "User";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub(crate) enum UserNotification {
  #[default]
  Unknown = 0,
  UserAuthStateChanged = 1,
  DidUpdateUserProfile = 2,
  DidUpdateUserWorkspaces = 3,
  DidUpdateCloudConfig = 4,
  DidUpdateUserWorkspace = 5,
}

impl std::convert::From<UserNotification> for i32 {
  fn from(notification: UserNotification) -> Self {
    notification as i32
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_notification(id: &str, ty: UserNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, USER_OBSERVABLE_SOURCE)
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_auth_state_notification(payload: AuthStateChangedPB) {
  NotificationBuilder::new(
    "auth_state_change_notification",
    UserNotification::UserAuthStateChanged,
    USER_OBSERVABLE_SOURCE,
  )
  .payload(payload)
  .send()
}
