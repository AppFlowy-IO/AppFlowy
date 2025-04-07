use crate::cloud::ai_dto::AvailableModel;
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
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use uuid::Uuid;

pub type ChatMessageStream = BoxStream<'static, Result<ChatMessage, AppResponseError>>;
pub type StreamAnswer = BoxStream<'static, Result<QuestionStreamValue, FlowyError>>;
pub type StreamComplete = BoxStream<'static, Result<CompletionStreamValue, FlowyError>>;

#[derive(Debug, Eq, PartialEq, Serialize, Deserialize, Clone)]
pub struct AIModel {
  pub name: String,
  pub is_local: bool,
  #[serde(default)]
  pub desc: String,
}

impl From<AvailableModel> for AIModel {
  fn from(value: AvailableModel) -> Self {
    let desc = value
      .metadata
      .as_ref()
      .and_then(|v| v.get("desc").map(|v| v.as_str().unwrap_or("")))
      .unwrap_or("");
    Self {
      name: value.name,
      is_local: false,
      desc: desc.to_string(),
    }
  }
}

impl AIModel {
  pub fn server(name: String, desc: String) -> Self {
    Self {
      name,
      is_local: false,
      desc,
    }
  }

  pub fn local(name: String, desc: String) -> Self {
    Self {
      name,
      is_local: true,
      desc,
    }
  }
}

pub const DEFAULT_AI_MODEL_NAME: &str = "Auto";
impl Default for AIModel {
  fn default() -> Self {
    Self {
      name: DEFAULT_AI_MODEL_NAME.to_string(),
      is_local: false,
      desc: "".to_string(),
    }
  }
}

#[async_trait]
pub trait ChatCloudService: Send + Sync + 'static {
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError>;

  async fn create_question(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    message_type: ChatMessageType,
    metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError>;

  async fn create_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError>;

  async fn stream_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    format: ResponseFormat,
    ai_model: Option<AIModel>,
  ) -> Result<StreamAnswer, FlowyError>;

  async fn get_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError>;

  async fn get_chat_messages(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError>;

  async fn get_question_from_answer_id(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError>;

  async fn get_related_message(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError>;

  async fn stream_complete(
    &self,
    workspace_id: &Uuid,
    params: CompleteTextParams,
    ai_model: Option<AIModel>,
  ) -> Result<StreamComplete, FlowyError>;

  async fn embed_file(
    &self,
    workspace_id: &Uuid,
    file_path: &Path,
    chat_id: &Uuid,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError>;

  async fn get_local_ai_config(&self, workspace_id: &Uuid) -> Result<LocalAIConfig, FlowyError>;

  async fn get_workspace_plan(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<SubscriptionPlan>, FlowyError>;

  async fn get_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError>;

  async fn update_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError>;

  async fn get_available_models(&self, workspace_id: &Uuid) -> Result<ModelList, FlowyError>;
  async fn get_workspace_default_model(&self, workspace_id: &Uuid) -> Result<String, FlowyError>;
}
