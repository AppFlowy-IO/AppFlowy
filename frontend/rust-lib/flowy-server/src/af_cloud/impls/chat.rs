#![allow(unused_variables)]
use crate::af_cloud::AFServer;
use client_api::entity::ai_dto::{
  ChatQuestionQuery, CompleteTextParams, RepeatedRelatedQuestion, ResponseFormat,
};
use client_api::entity::chat_dto::{
  CreateAnswerMessageParams, CreateChatMessageParams, CreateChatParams, MessageCursor,
  RepeatedChatMessage,
};
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, ChatMessageMetadata, ChatMessageType, ChatSettings,
  ModelList, StreamAnswer, StreamComplete, SubscriptionPlan, UpdateChatParams,
};
use flowy_error::FlowyError;
use futures_util::{StreamExt, TryStreamExt};
use lib_infra::async_trait::async_trait;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use tracing::trace;
use uuid::Uuid;

pub(crate) struct AFCloudChatCloudServiceImpl<T> {
  pub inner: T,
}

#[async_trait]
impl<T> ChatCloudService for AFCloudChatCloudServiceImpl<T>
where
  T: AFServer,
{
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = CreateChatParams {
      chat_id,
      name: "".to_string(),
      rag_ids,
    };
    try_get_client?
      .create_chat(workspace_id, params)
      .await
      .map_err(FlowyError::from)?;

    Ok(())
  }

  async fn create_question(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    message_type: ChatMessageType,
    metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = CreateChatMessageParams {
      content: message.to_string(),
      message_type,
    };

    let message = try_get_client?
      .create_question(workspace_id, &chat_id, params)
      .await
      .map_err(FlowyError::from)?;
    Ok(message)
  }

  async fn create_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let params = CreateAnswerMessageParams {
      content: message.to_string(),
      metadata,
      question_message_id: question_id,
    };
    let message = try_get_client?
      .save_answer(workspace_id, chat_id.to_string().as_str(), params)
      .await
      .map_err(FlowyError::from)?;
    Ok(message)
  }

  async fn stream_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    format: ResponseFormat,
    ai_model: Option<AIModel>,
  ) -> Result<StreamAnswer, FlowyError> {
    trace!(
      "stream_answer: workspace_id={}, chat_id={}, format={:?}, model: {:?}",
      workspace_id,
      chat_id,
      format,
      ai_model,
    );
    let try_get_client = self.inner.try_get_client();
    let result = try_get_client?
      .stream_answer_v3(
        workspace_id,
        ChatQuestionQuery {
          chat_id: chat_id.to_string(),
          question_id: message_id,
          format,
        },
        ai_model.map(|v| v.name),
      )
      .await;

    let stream = result.map_err(FlowyError::from)?.map_err(FlowyError::from);
    Ok(stream.boxed())
  }

  async fn get_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let resp = try_get_client?
      .get_answer(
        workspace_id,
        chat_id.to_string().as_str(),
        question_message_id,
      )
      .await
      .map_err(FlowyError::from)?;
    Ok(resp)
  }

  async fn get_chat_messages(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let resp = try_get_client?
      .get_chat_messages(workspace_id, chat_id.to_string().as_str(), offset, limit)
      .await
      .map_err(FlowyError::from)?;

    Ok(resp)
  }

  async fn get_question_from_answer_id(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let try_get_client = self.inner.try_get_client()?;
    let resp = try_get_client
      .get_question_message_from_answer_id(
        workspace_id,
        chat_id.to_string().as_str(),
        answer_message_id,
      )
      .await
      .map_err(FlowyError::from)?
      .ok_or_else(FlowyError::record_not_found)?;

    Ok(resp)
  }

  async fn get_related_message(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    ai_model: Option<AIModel>,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let resp = try_get_client?
      .get_chat_related_question(workspace_id, chat_id.to_string().as_str(), message_id)
      .await
      .map_err(FlowyError::from)?;

    Ok(resp)
  }

  async fn stream_complete(
    &self,
    workspace_id: &Uuid,
    params: CompleteTextParams,
    ai_model: Option<AIModel>,
  ) -> Result<StreamComplete, FlowyError> {
    let stream = self
      .inner
      .try_get_client()?
      .stream_completion_v2(workspace_id, params, ai_model.map(|v| v.name))
      .await
      .map_err(FlowyError::from)?
      .map_err(FlowyError::from);

    Ok(stream.boxed())
  }

  async fn embed_file(
    &self,
    workspace_id: &Uuid,
    file_path: &Path,
    chat_id: &Uuid,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    return Err(
      FlowyError::not_support()
        .with_context("indexing file with appflowy cloud is not suppotred yet"),
    );
  }

  async fn get_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    let settings = self
      .inner
      .try_get_client()?
      .get_chat_settings(workspace_id, chat_id.to_string().as_str())
      .await?;
    Ok(settings)
  }

  async fn update_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    self
      .inner
      .try_get_client()?
      .update_chat_settings(workspace_id, chat_id.to_string().as_str(), params)
      .await?;
    Ok(())
  }

  async fn get_available_models(&self, workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    let list = self
      .inner
      .try_get_client()?
      .get_model_list(workspace_id)
      .await?;
    Ok(list)
  }

  async fn get_workspace_default_model(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    let setting = self
      .inner
      .try_get_client()?
      .get_workspace_settings(workspace_id.to_string().as_str())
      .await?;
    Ok(setting.ai_model)
  }
}
