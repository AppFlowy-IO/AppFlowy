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
    _uid: &i64,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _rag_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn create_question(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _message: &str,
    _message_type: ChatMessageType,
    _metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn create_answer(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _message: &str,
    _question_id: i64,
    _metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn stream_answer(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _message_id: i64,
    _format: ResponseFormat,
    _ai_model: Option<AIModel>,
  ) -> Result<StreamAnswer, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_chat_messages(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _offset: MessageCursor,
    _limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_question_from_answer_id(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_related_message(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_answer(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn stream_complete(
    &self,
    _workspace_id: &Uuid,
    _params: CompleteTextParams,
    _ai_model: Option<AIModel>,
  ) -> Result<StreamComplete, FlowyError> {
    Err(FlowyError::not_support().with_context("complete text is not supported in local server."))
  }

  async fn embed_file(
    &self,
    _workspace_id: &Uuid,
    _file_path: &Path,
    _chat_id: &Uuid,
    _metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("indexing file is not supported in local server."))
  }

  async fn get_local_ai_config(&self, _workspace_id: &Uuid) -> Result<LocalAIConfig, FlowyError> {
    Err(
      FlowyError::not_support()
        .with_context("Get local ai config is not supported in local server."),
    )
  }

  async fn get_workspace_plan(
    &self,
    _workspace_id: &Uuid,
  ) -> Result<Vec<SubscriptionPlan>, FlowyError> {
    Err(
      FlowyError::not_support()
        .with_context("Get local ai config is not supported in local server."),
    )
  }

  async fn get_chat_settings(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn update_chat_settings(
    &self,
    _workspace_id: &Uuid,
    _id: &Uuid,
    _s: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_available_models(&self, _workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_workspace_default_model(&self, _workspace_id: &Uuid) -> Result<String, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }
}
