pub use client_api::entity::ai_dto::{
  AppFlowyOfflineAI, CompleteTextParams, CompletionMessage, CompletionMetadata, CompletionType,
  CreateChatContext, CustomPrompt, LLMModel, LocalAIConfig, ModelInfo, ModelList, OutputContent,
  OutputLayout, RelatedQuestion, RepeatedRelatedQuestion, ResponseFormat, StringOrMessage,
};
pub use client_api::entity::billing_dto::SubscriptionPlan;
pub use client_api::entity::chat_dto::{
  ChatMessage, ChatMessageMetadata, ChatMessageType, ChatRAGData, ChatSettings, ContextLoader,
  MessageCursor, RepeatedChatMessage, UpdateChatParams,
};
pub use client_api::entity::QuestionStreamValue;
pub use client_api::entity::*;
pub use client_api::error::{AppResponseError, ErrorCode as AppErrorCode};
use flowy_error::FlowyError;
use futures::stream::BoxStream;
use lib_infra::async_trait::async_trait;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;

pub type ChatMessageStream = BoxStream<'static, Result<ChatMessage, AppResponseError>>;
pub type StreamAnswer = BoxStream<'static, Result<QuestionStreamValue, FlowyError>>;
pub type StreamComplete = BoxStream<'static, Result<CompletionStreamValue, FlowyError>>;
#[async_trait]
pub trait ChatCloudService: Send + Sync + 'static {
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &str,
    chat_id: &str,
    rag_ids: Vec<String>,
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
    format: ResponseFormat,
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

  async fn get_question_from_answer_id(
    &self,
    workspace_id: &str,
    chat_id: &str,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError>;

  async fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError>;

  async fn stream_complete(
    &self,
    workspace_id: &str,
    params: CompleteTextParams,
  ) -> Result<StreamComplete, FlowyError>;

  async fn embed_file(
    &self,
    workspace_id: &str,
    file_path: &Path,
    chat_id: &str,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError>;

  async fn get_local_ai_config(&self, workspace_id: &str) -> Result<LocalAIConfig, FlowyError>;

  async fn get_workspace_plan(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<SubscriptionPlan>, FlowyError>;

  async fn get_chat_settings(
    &self,
    workspace_id: &str,
    chat_id: &str,
  ) -> Result<ChatSettings, FlowyError>;

  async fn update_chat_settings(
    &self,
    workspace_id: &str,
    chat_id: &str,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError>;

  async fn get_available_models(&self, workspace_id: &str) -> Result<ModelList, FlowyError>;
}
