use client_api::entity::ai_dto::RepeatedRelatedQuestion;
use client_api::entity::{ChatMessageType, MessageCursor, RepeatedChatMessage};
use flowy_chat_pub::cloud::{ChatCloudService, ChatMessage, StreamAnswer};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

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

  fn save_question(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message: &str,
    _message_type: ChatMessageType,
  ) -> FutureResult<ChatMessage, FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  fn save_answer(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message: &str,
    _question_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  async fn ask_question(
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

  fn get_related_message(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _message_id: i64,
  ) -> FutureResult<RepeatedRelatedQuestion, FlowyError> {
    FutureResult::new(async move {
      Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
    })
  }

  async fn generate_answer(
    &self,
    _workspace_id: &str,
    _chat_id: &str,
    _question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }
}
