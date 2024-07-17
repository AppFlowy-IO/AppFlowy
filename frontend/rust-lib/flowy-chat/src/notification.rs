use flowy_derive::ProtoBuf_Enum;
use flowy_notification::NotificationBuilder;

const CHAT_OBSERVABLE_SOURCE: &str = "Chat";
pub const APPFLOWY_AI_NOTIFICATION_KEY: &str = "appflowy_ai_plugin";
#[derive(ProtoBuf_Enum, Debug, Default)]
pub enum ChatNotification {
  #[default]
  Unknown = 0,
  DidLoadLatestChatMessage = 1,
  DidLoadPrevChatMessage = 2,
  DidReceiveChatMessage = 3,
  StreamChatMessageError = 4,
  FinishStreaming = 5,
  UpdateChatPluginState = 6,
}

impl std::convert::From<ChatNotification> for i32 {
  fn from(notification: ChatNotification) -> Self {
    notification as i32
  }
}
impl std::convert::From<i32> for ChatNotification {
  fn from(notification: i32) -> Self {
    match notification {
      1 => ChatNotification::DidLoadLatestChatMessage,
      2 => ChatNotification::DidLoadPrevChatMessage,
      3 => ChatNotification::DidReceiveChatMessage,
      4 => ChatNotification::StreamChatMessageError,
      5 => ChatNotification::FinishStreaming,
      6 => ChatNotification::UpdateChatPluginState,
      _ => ChatNotification::Unknown,
    }
  }
}

#[tracing::instrument(level = "trace")]
pub(crate) fn send_notification(id: &str, ty: ChatNotification) -> NotificationBuilder {
  NotificationBuilder::new(id, ty, CHAT_OBSERVABLE_SOURCE)
}
