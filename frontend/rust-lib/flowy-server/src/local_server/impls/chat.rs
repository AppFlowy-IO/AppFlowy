use crate::af_cloud::define::ServerUser;
use client_api::entity::ai_dto::RepeatedRelatedQuestion;
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, ChatMessageMetadata, ChatMessageType, ChatSettings,
  CompleteTextParams, MessageCursor, ModelList, RepeatedChatMessage, ResponseFormat, StreamAnswer,
  StreamComplete, SubscriptionPlan, UpdateChatParams,
};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use lib_infra::util::timestamp;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use uuid::Uuid;

pub struct LocalServerChatServiceImpl {
  pub user: Arc<dyn ServerUser>,
}

#[async_trait]
impl ChatCloudService for LocalServerChatServiceImpl {
  async fn create_chat(
    &self,
    _uid: &i64,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _rag_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn create_question(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    message: &str,
    message_type: ChatMessageType,
    _metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    match message_type {
      ChatMessageType::System => Ok(ChatMessage::new_system(timestamp(), message.to_string())),
      ChatMessageType::User => Ok(ChatMessage::new_human(
        timestamp(),
        message.to_string(),
        None,
      )),
    }
  }

  async fn create_answer(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError> {
    let mut message = ChatMessage::new_ai(timestamp(), message.to_string(), Some(question_id));
    if let Some(metadata) = metadata {
      message.metadata = metadata;
    }
    Ok(message)
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
    message_id: i64,
    ai_model: Option<AIModel>,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    Ok(RepeatedRelatedQuestion {
      message_id,
      items: vec![],
    })
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
