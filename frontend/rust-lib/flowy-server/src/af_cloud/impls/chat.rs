use crate::af_cloud::AFServer;
use client_api::entity::ai_dto::RepeatedRelatedQuestion;
use client_api::entity::{
  CreateAnswerMessageParams, CreateChatMessageParams, CreateChatParams, MessageCursor,
  RepeatedChatMessage,
};
use flowy_chat_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageStream, ChatMessageType, StreamAnswer,
};
use flowy_error::FlowyError;
use futures_util::StreamExt;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

pub(crate) struct AFCloudChatCloudServiceImpl<T> {
  pub inner: T,
}

#[async_trait]
impl<T> ChatCloudService for AFCloudChatCloudServiceImpl<T>
where
  T: AFServer,
{
  fn create_chat(
    &self,
    _uid: &i64,
    workspace_id: &str,
    chat_id: &str,
  ) -> FutureResult<(), FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();

    FutureResult::new(async move {
      let params = CreateChatParams {
        chat_id,
        name: "".to_string(),
        rag_ids: vec![],
      };
      try_get_client?
        .create_chat(&workspace_id, params)
        .await
        .map_err(FlowyError::from)?;

      Ok(())
    })
  }

  async fn send_chat_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<ChatMessageStream, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let params = CreateChatMessageParams {
      content: message.to_string(),
      message_type,
    };
    let stream = try_get_client?
      .create_chat_qa_message(workspace_id, chat_id, params)
      .await
      .map_err(FlowyError::from)?;

    Ok(stream.boxed())
  }

  fn send_question(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
  ) -> FutureResult<ChatMessage, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = CreateChatMessageParams {
      content: message.to_string(),
      message_type,
    };

    FutureResult::new(async move {
      let message = try_get_client?
        .create_question(&workspace_id, &chat_id, params)
        .await
        .map_err(FlowyError::from)?;
      Ok(message)
    })
  }

  fn save_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    question_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = CreateAnswerMessageParams {
      content: message.to_string(),
      question_message_id: question_id,
    };

    FutureResult::new(async move {
      let message = try_get_client?
        .create_answer(&workspace_id, &chat_id, params)
        .await
        .map_err(FlowyError::from)?;
      Ok(message)
    })
  }

  async fn stream_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let stream = try_get_client?
      .stream_answer(workspace_id, chat_id, message_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(stream.boxed())
  }

  fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> FutureResult<RepeatedChatMessage, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();

    FutureResult::new(async move {
      let resp = try_get_client?
        .get_chat_messages(&workspace_id, &chat_id, offset, limit)
        .await
        .map_err(FlowyError::from)?;

      Ok(resp)
    })
  }

  fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> FutureResult<RepeatedRelatedQuestion, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();

    FutureResult::new(async move {
      let resp = try_get_client?
        .get_chat_related_question(&workspace_id, &chat_id, message_id)
        .await
        .map_err(FlowyError::from)?;

      Ok(resp)
    })
  }

  fn generate_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> FutureResult<ChatMessage, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();

    FutureResult::new(async move {
      let resp = try_get_client?
        .get_answer(&workspace_id, &chat_id, question_message_id)
        .await
        .map_err(FlowyError::from)?;
      Ok(resp)
    })
  }
}
