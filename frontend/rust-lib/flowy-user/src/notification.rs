use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;
const OBSERVABLE_CATEGORY: &str = "User";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum UserNotification {
  Unknown = 0,
  DidUserSignIn = 1,
  DidUpdateUserProfile = 2,
}

impl std::default::Default for UserNotification {
  fn default() -> Self {
    UserNotification::Unknown
  }
}

impl std::convert::From<UserNotification> for i32 {
  fn from(notification: UserNotification) -> Self {
    notification as i32
  }
}

pub(crate) fn send_notification(id: &str, ty: UserNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, OBSERVABLE_CATEGORY)
}

pub(crate) fn send_sign_in_notification() -> NotificationBuilder {
  NotificationBuilder::new("", UserNotification::DidUserSignIn, OBSERVABLE_CATEGORY)
}
