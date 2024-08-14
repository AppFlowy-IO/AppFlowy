use bytes::Bytes;
pub use client_api::entity::ai_dto::{
  AppFlowyOfflineAI, CompletionType, CreateTextChatContext, LLMModel, LocalAIConfig, ModelInfo,
  RelatedQuestion, RepeatedRelatedQuestion, StringOrMessage,
};
pub use client_api::entity::{
  ChatAuthorType, ChatMessage, ChatMessageMetadata, ChatMessageType, ChatMetadataContentType,
  ChatMetadataData, MessageCursor, QAChatMessage, QuestionStreamValue, RepeatedChatMessage,
};
use client_api::error::AppResponseError;
use flowy_error::FlowyError;
use futures::stream::BoxStream;
use lib_infra::async_trait::async_trait;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;

pub type ChatMessageStream = BoxStream<'static, Result<ChatMessage, AppResponseError>>;
pub type StreamAnswer = BoxStream<'static, Result<QuestionStreamValue, FlowyError>>;
pub type StreamComplete = BoxStream<'static, Result<Bytes, FlowyError>>;
#[async_trait]
pub trait ChatCloudService: Send + Sync + 'static {
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> Result<(), FlowyError>;

  async fn create_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
    metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError>;

  async fn create_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError>;

  async fn stream_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<StreamAnswer, FlowyError>;

  async fn get_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError>;

  async fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError>;

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
    file_path: &Path,
    chat_id: &str,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError>;

  async fn get_local_ai_config(&self, workspace_id: &str) -> Result<LocalAIConfig, FlowyError>;

  async fn create_chat_context(
    &self,
    _workspace_id: &str,
    _chat_context: CreateTextChatContext,
  ) -> Result<(), FlowyError> {
    Ok(())
  }
}
