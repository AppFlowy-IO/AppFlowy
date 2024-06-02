pub use client_api::entity::ai_dto::{RelatedQuestion, RepeatedRelatedQuestion};
pub use client_api::entity::{
  ChatMessage, ChatMessageType, MessageCursor, QAChatMessage, RepeatedChatMessage,
};
use client_api::error::AppResponseError;
use flowy_error::FlowyError;
use futures::stream::BoxStream;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

pub type ChatMessageStream = BoxStream<'static, Result<ChatMessage, AppResponseError>>;
#[async_trait]
pub trait ChatCloudService: Send + Sync + 'static {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError>;

  async fn send_chat_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<ChatMessageStream, FlowyError>;

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError>;

  fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> FutureResult<RepeatedRelatedQuestion, FlowyError>;
}
