use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

const OPEN_AI_NOTIFICATION: &str = "OpenAI";

#[derive(ProtoBuf_Enum, Debug, Default)]
pub(crate) enum OpenAINotification {
  #[default]
  Unknown = 0,
}

impl std::convert::From<OpenAINotification> for i32 {
  fn from(notification: OpenAINotification) -> Self {
    notification as i32
  }
}

pub(crate) fn send_notification(id: &str, ty: OpenAINotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, OPEN_AI_NOTIFICATION)
}
