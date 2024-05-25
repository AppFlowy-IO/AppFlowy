pub use client_api::entity::{
  ChatMessage, ChatMessageType, MessageCursor, QAChatMessage, RepeatedChatMessage,
};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub trait ChatCloudService: Send + Sync + 'static {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError>;

  fn send_system_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
  ) -> FutureResult<ChatMessage, FlowyError>;

  fn send_user_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
  ) -> FutureResult<QAChatMessage, FlowyError>;

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError>;
}
