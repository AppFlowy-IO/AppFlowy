pub use client_api::entity::{ChatMessage, MessageOffset, RepeatedChatMessage};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub trait ChatCloudService: Send + Sync + 'static {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError>;

  fn send_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
  ) -> FutureResult<ChatMessage, FlowyError>;

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageOffset,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError>;
}
