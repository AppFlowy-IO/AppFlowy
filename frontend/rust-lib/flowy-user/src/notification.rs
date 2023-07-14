use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
const USER_OBSERVABLE_SOURCE: &str = "User";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub(crate) enum UserNotification {
  #[default]
  Unknown = 0,
  DidUserSignIn = 1,
  DidUpdateUserProfile = 2,
}

impl std::convert::From<UserNotification> for i32 {
  fn from(notification: UserNotification) -> Self {
    notification as i32
  }
}

pub(crate) fn send_notification(id: &str, ty: UserNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, USER_OBSERVABLE_SOURCE)
}

pub(crate) fn send_sign_in_notification() -> NotificationBuilder {
  NotificationBuilder::new("", UserNotification::DidUserSignIn, USER_OBSERVABLE_SOURCE)
}
