use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, ChatMessageType, ChatSettings, CompleteTextParams,
  MessageCursor, ModelList, RepeatedChatMessage, RepeatedRelatedQuestion, ResponseFormat,
  StreamAnswer, StreamComplete, UpdateChatParams,
};
use flowy_ai_pub::persistence::{
  ChatMessageTable, ChatTable, update_chat_is_sync, update_chat_message_is_sync, upsert_chat,
  upsert_chat_messages,
};
use flowy_ai_pub::user_service::AIUserService;
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use uuid::Uuid;

pub struct AutoSyncChatService {
  cloud_service: Arc<dyn ChatCloudService>,
  user_service: Arc<dyn AIUserService>,
}

impl AutoSyncChatService {
  pub fn new(
    cloud_service: Arc<dyn ChatCloudService>,
    user_service: Arc<dyn AIUserService>,
  ) -> Self {
    Self {
      cloud_service,
      user_service,
    }
  }

  async fn upsert_message(
    &self,
    chat_id: &Uuid,
    message: ChatMessage,
    is_sync: bool,
  ) -> Result<(), FlowyError> {
    let uid = self.user_service.user_id()?;
    let conn = self.user_service.sqlite_connection(uid)?;
    let row = ChatMessageTable::from_message(chat_id.to_string(), message, is_sync);
    upsert_chat_messages(conn, &[row])?;
    Ok(())
  }

  #[allow(dead_code)]
  async fn update_message_is_sync(
    &self,
    chat_id: &Uuid,
    message_id: i64,
  ) -> Result<(), FlowyError> {
    let uid = self.user_service.user_id()?;
    let conn = self.user_service.sqlite_connection(uid)?;
    update_chat_message_is_sync(conn, &chat_id.to_string(), message_id, true)?;
    Ok(())
  }
}

#[async_trait]
impl ChatCloudService for AutoSyncChatService {
  async fn create_chat(
    &self,
    uid: &i64,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
    name: &str,
    metadata: Value,
  ) -> Result<(), FlowyError> {
    let conn = self.user_service.sqlite_connection(*uid)?;
    let chat = ChatTable::new(
      chat_id.to_string(),
      metadata.clone(),
      rag_ids.clone(),
      false,
    );
    upsert_chat(conn, &chat)?;

    if self
      .cloud_service
      .create_chat(uid, workspace_id, chat_id, rag_ids, name, metadata)
      .await
      .is_ok()
    {
      let conn = self.user_service.sqlite_connection(*uid)?;
      update_chat_is_sync(conn, &chat_id.to_string(), true)?;
    }
    Ok(())
  }

  async fn create_question(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    message_type: ChatMessageType,
    prompt_id: Option<String>,
  ) -> Result<ChatMessage, FlowyError> {
    let message = self
      .cloud_service
      .create_question(workspace_id, chat_id, message, message_type, prompt_id)
      .await?;
    self.upsert_message(chat_id, message.clone(), true).await?;
    // TODO: implement background sync
    // self
    //   .update_message_is_sync(chat_id, message.message_id)
    //   .await?;
    Ok(message)
  }

  async fn create_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    question_id: i64,
    metadata: Option<Value>,
  ) -> Result<ChatMessage, FlowyError> {
    let message = self
      .cloud_service
      .create_answer(workspace_id, chat_id, message, question_id, metadata)
      .await?;

    // TODO: implement background sync
    self.upsert_message(chat_id, message.clone(), true).await?;
    Ok(message)
  }

  async fn stream_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_id: i64,
    format: ResponseFormat,
    ai_model: AIModel,
  ) -> Result<StreamAnswer, FlowyError> {
    self
      .cloud_service
      .stream_answer(workspace_id, chat_id, question_id, format, ai_model)
      .await
  }

  async fn get_answer(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    question_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let message = self
      .cloud_service
      .get_answer(workspace_id, chat_id, question_id)
      .await?;

    // TODO: implement background sync
    self.upsert_message(chat_id, message.clone(), true).await?;
    Ok(message)
  }

  async fn get_chat_messages(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    self
      .cloud_service
      .get_chat_messages(workspace_id, chat_id, offset, limit)
      .await
  }

  async fn get_question_from_answer_id(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    self
      .cloud_service
      .get_question_from_answer_id(workspace_id, chat_id, answer_message_id)
      .await
  }

  async fn get_related_message(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    ai_model: AIModel,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    self
      .cloud_service
      .get_related_message(workspace_id, chat_id, message_id, ai_model)
      .await
  }

  async fn stream_complete(
    &self,
    workspace_id: &Uuid,
    params: CompleteTextParams,
    ai_model: AIModel,
  ) -> Result<StreamComplete, FlowyError> {
    self
      .cloud_service
      .stream_complete(workspace_id, params, ai_model)
      .await
  }

  async fn embed_file(
    &self,
    workspace_id: &Uuid,
    file_path: &Path,
    chat_id: &Uuid,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    self
      .cloud_service
      .embed_file(workspace_id, file_path, chat_id, metadata)
      .await
  }

  async fn get_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    // TODO: implement background sync
    self
      .cloud_service
      .get_chat_settings(workspace_id, chat_id)
      .await
  }

  async fn update_chat_settings(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    params: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    // TODO: implement background sync
    self
      .cloud_service
      .update_chat_settings(workspace_id, chat_id, params)
      .await
  }

  async fn get_available_models(&self, workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    self.cloud_service.get_available_models(workspace_id).await
  }

  async fn get_workspace_default_model(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    self
      .cloud_service
      .get_workspace_default_model(workspace_id)
      .await
  }

  async fn set_workspace_default_model(
    &self,
    workspace_id: &Uuid,
    model: &str,
  ) -> Result<(), FlowyError> {
    self
      .cloud_service
      .set_workspace_default_model(workspace_id, model)
      .await
  }
}
