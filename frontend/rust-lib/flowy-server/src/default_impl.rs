use client_api::entity::ai_dto::{LocalAIConfig, RepeatedRelatedQuestion};
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, ChatMessageMetadata, ChatMessageType, ChatSettings,
  CompleteTextParams, MessageCursor, ModelList, RepeatedChatMessage, ResponseFormat, StreamAnswer,
  StreamComplete, SubscriptionPlan, UpdateChatParams,
};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use uuid::Uuid;

pub(crate) struct DefaultChatCloudServiceImpl;

#[async_trait]
impl ChatCloudService for DefaultChatCloudServiceImpl {
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn create_question(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    message_type: ChatMessageType,
    metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn create_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn stream_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    format: ResponseFormat,
    ai_model: Option<AIModel>,
  ) -> Result<StreamAnswer, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_chat_messages(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_question_from_answer_id(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_related_message(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn stream_complete(
    &self,
    workspace_id: &Uuid,
    params: CompleteTextParams,
    ai_model: Option<AIModel>,
  ) -> Result<StreamComplete, FlowyError> {
    Err(FlowyError::not_support().with_context("complete text is not supported in local server."))
  }

  async fn embed_file(
    &self,
    workspace_id: &Uuid,
    file_path: &Path,
    chat_id: &Uuid,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("indexing file is not supported in local server."))
  }

  async fn get_local_ai_config(&self, workspace_id: &Uuid) -> Result<LocalAIConfig, FlowyError> {
    Err(
      FlowyError::not_support()
        .with_context("Get local ai config is not supported in local server."),
    )
  }

  async fn get_workspace_plan(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<SubscriptionPlan>, FlowyError> {
    Err(
      FlowyError::not_support()
        .with_context("Get local ai config is not supported in local server."),
    )
  }

  async fn get_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn update_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_available_models(&self, workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_workspace_default_model(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }
}
