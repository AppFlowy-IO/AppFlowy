use bytes::Bytes;
pub use client_api::entity::ai_dto::{
  AppFlowyAIPlugin, CompletionType, LLMModel, LocalAIConfig, ModelInfo, RelatedQuestion,
  RepeatedRelatedQuestion, StringOrMessage,
};
pub use client_api::entity::{
  ChatAuthorType, ChatMessage, ChatMessageType, MessageCursor, QAChatMessage, RepeatedChatMessage,
};
use client_api::error::AppResponseError;
use flowy_error::FlowyError;
use futures::stream::BoxStream;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;
use std::path::PathBuf;

pub type ChatMessageStream = BoxStream<'static, Result<ChatMessage, AppResponseError>>;
pub type StreamAnswer = BoxStream<'static, Result<Bytes, FlowyError>>;
pub type StreamComplete = BoxStream<'static, Result<Bytes, FlowyError>>;
#[async_trait]
pub trait ChatCloudService: Send + Sync + 'static {
  fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError>;

  fn save_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> FutureResult<ChatMessage, FlowyError>;

  fn save_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError>;

  async fn ask_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<StreamAnswer, FlowyError>;

  async fn generate_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError>;

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError>;

  async fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError>;

  async fn stream_complete(
    &self,
    workspace_id: &str,
    text: &str,
    complete_type: CompletionType,
  ) -> Result<StreamComplete, FlowyError>;

  async fn index_file(
    &self,
    workspace_id: &str,
    file_path: PathBuf,
    chat_id: &str,
  ) -> Result<(), FlowyError>;

  async fn get_local_ai_config(&self, workspace_id: &str) -> Result<LocalAIConfig, FlowyError>;
}
