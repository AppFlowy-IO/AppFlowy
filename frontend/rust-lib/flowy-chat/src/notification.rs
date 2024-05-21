use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

const CHAT_OBSERVABLE_SOURCE: &str = "Chat";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub enum ChatNotification {
  #[default]
  Unknown = 0,
  DidReceiveResponse = 1,
}

impl std::convert::From<ChatNotification> for i32 {
  fn from(notification: ChatNotification) -> Self {
    notification as i32
  }
}
impl std::convert::From<i32> for ChatNotification {
  fn from(notification: i32) -> Self {
    match notification {
      1 => ChatNotification::DidReceiveResponse,
      _ => ChatNotification::Unknown,
    }
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_notification(id: &str, ty: ChatNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, CHAT_OBSERVABLE_SOURCE)
}
