use client_api::entity::ai_dto::{CompletionType, LocalAIConfig, RepeatedRelatedQuestion};
use client_api::entity::{ChatMessageType, MessageCursor, RepeatedChatMessage};
use flowy_ai_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageMetadata, StreamAnswer, StreamComplete,
};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;
use std::path::Path;

pub(crate) struct DefaultChatCloudServiceImpl;

#[async_trait]
impl ChatCloudService for DefaultChatCloudServiceImpl {
  fn create_chat(
    &self,
    _uid: &i64,
    _workspace_id: &str,
    _chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  async fn create_question(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message: &str,
    _message_type: ChatMessageType,
    _metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  fn create_answer(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message: &str,
    _question_id: i64,
    _metadata: Option<serde_json::Value>,
  ) -> FutureResult<ChatMessage, FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  async fn stream_answer(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  fn get_chat_messages(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _offset: MessageCursor,
    _limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  async fn get_related_message(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_answer(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn stream_complete(
    &self,
    _workspace_id: &str,
    _text: &str,
    _complete_type: CompletionType,
  ) -> Result<StreamComplete, FlowyError> {
    Err(FlowyError::not_support().with_context("complete text is not supported in local server."))
  }

  async fn index_file(
    &self,
    _workspace_id: &str,
    _file_path: &Path,
    _chat_id: &str,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support().with_context("indexing file is not supported in local server."))
  }

  async fn get_local_ai_config(&self, _workspace_id: &str) -> Result<LocalAIConfig, FlowyError> {
    Err(
      FlowyError::not_support()
        .with_context("Get local ai config is not supported in local server."),
    )
  }
}
