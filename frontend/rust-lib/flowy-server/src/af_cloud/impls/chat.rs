use crate::af_cloud::AFServer;
use client_api::entity::ai_dto::{CompleteTextParams, CompletionType, RepeatedRelatedQuestion};
use client_api::entity::chat_dto::{
  CreateAnswerMessageParams, CreateChatMessageParams, CreateChatParams, MessageCursor,
  RepeatedChatMessage,
};
use flowy_ai_pub::cloud::{
  ChatCloudService, ChatMessage, ChatMessageMetadata, ChatMessageType, ChatSettings, LocalAIConfig,
  StreamAnswer, StreamComplete, SubscriptionPlan, UpdateChatParams,
};
use flowy_error::FlowyError;
use futures_util::{StreamExt, TryStreamExt};
use lib_infra::async_trait::async_trait;
use lib_infra::util::{get_operating_system, OperatingSystem};
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;

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
    _uid: &i64,
    workspace_id: &str,
    chat_id: &str,
    rag_ids: Vec<String>,
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
    workspace_id: &str,
    chat_id: &str,
    message: &str,
    message_type: ChatMessageType,
    metadata: &[ChatMessageMetadata],
  ) -> Result<ChatMessage, FlowyError> {
    let workspace_id = workspace_id.to_string();
    let chat_id = chat_id.to_string();
    let try_get_client = self.inner.try_get_client();
    let params = CreateChatMessageParams {
      content: message.to_string(),
      message_type,
      metadata: metadata.to_vec(),
    };

    let message = try_get_client?
      .create_question(&workspace_id, &chat_id, params)
      .await
      .map_err(FlowyError::from)?;
    Ok(message)
  }

  async fn create_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
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
      .save_answer(workspace_id, chat_id, params)
      .await
      .map_err(FlowyError::from)?;
    Ok(message)
  }

  async fn stream_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<StreamAnswer, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let stream = try_get_client?
      .stream_answer_v2(workspace_id, chat_id, message_id)
      .await
      .map_err(FlowyError::from)?
      .map_err(FlowyError::from);
    Ok(stream.boxed())
  }

  async fn get_answer(
    &self,
    workspace_id: &str,
    chat_id: &str,
    question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let resp = try_get_client?
      .get_answer(workspace_id, chat_id, question_message_id)
      .await
      .map_err(FlowyError::from)?;
    Ok(resp)
  }

  async fn get_chat_messages(
    &self,
    workspace_id: &str,
    chat_id: &str,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let resp = try_get_client?
      .get_chat_messages(workspace_id, chat_id, offset, limit)
      .await
      .map_err(FlowyError::from)?;

    Ok(resp)
  }

  async fn get_related_message(
    &self,
    workspace_id: &str,
    chat_id: &str,
    message_id: i64,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    let try_get_client = self.inner.try_get_client();
    let resp = try_get_client?
      .get_chat_related_question(workspace_id, chat_id, message_id)
      .await
      .map_err(FlowyError::from)?;

    Ok(resp)
  }

  async fn stream_complete(
    &self,
    workspace_id: &str,
    text: &str,
    completion_type: CompletionType,
  ) -> Result<StreamComplete, FlowyError> {
    // TODO(Nathan): Check if this is correct after updating to latest client-api
    let params = CompleteTextParams {
      text: text.to_string(),
      completion_type: Some(completion_type),
      custom_prompt: None,
    };
    let stream = self
      .inner
      .try_get_client()?
      .stream_completion_text(workspace_id, params)
      .await
      .map_err(FlowyError::from)?
      .map_err(FlowyError::from);
    Ok(stream.boxed())
  }

  async fn index_file(
    &self,
    _workspace_id: &str,
    _file_path: &Path,
    _chat_id: &str,
    _metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    return Err(
      FlowyError::not_support()
        .with_context("indexing file with appflowy cloud is not suppotred yet"),
    );
  }

  async fn get_local_ai_config(&self, workspace_id: &str) -> Result<LocalAIConfig, FlowyError> {
    let system = get_operating_system();
    let platform = match system {
      OperatingSystem::MacOS => "macos",
      _ => {
        return Err(
          FlowyError::not_support()
            .with_context("local ai is not supported on this operating system"),
        );
      },
    };
    let config = self
      .inner
      .try_get_client()?
      .get_local_ai_config(workspace_id, platform)
      .await?;
    Ok(config)
  }

  async fn get_workspace_plan(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<SubscriptionPlan>, FlowyError> {
    let plans = self
      .inner
      .try_get_client()?
      .get_active_workspace_subscriptions(workspace_id)
      .await?;
    Ok(plans)
  }

  async fn get_chat_settings(
    &self,
    workspace_id: &str,
    chat_id: &str,
  ) -> Result<ChatSettings, FlowyError> {
    let settings = self
      .inner
      .try_get_client()?
      .get_chat_settings(workspace_id, chat_id)
      .await?;
    Ok(settings)
  }

  async fn update_chat_settings(
    &self,
    workspace_id: &str,
    chat_id: &str,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    self
      .inner
      .try_get_client()?
      .update_chat_settings(workspace_id, chat_id, params)
      .await?;
    Ok(())
  }
}
