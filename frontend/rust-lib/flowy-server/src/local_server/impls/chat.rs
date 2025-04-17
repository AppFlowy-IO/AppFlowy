use crate::af_cloud::define::ServerUser;
use client_api::entity::ai_dto::RepeatedRelatedQuestion;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_ai::local_ai::stream_util::QuestionStream;
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, ChatMessageMetadata, ChatMessageType, ChatSettings,
  CompleteTextParams, MessageCursor, ModelList, RepeatedChatMessage, ResponseFormat, StreamAnswer,
  StreamComplete, SubscriptionPlan, UpdateChatParams,
};
use flowy_ai_pub::persistence::{
  deserialize_chat_metadata, deserialize_rag_ids, read_chat, select_message_content,
  serialize_chat_metadata, serialize_rag_ids, update_chat, upsert_chat, ChatTable,
  ChatTableChangeset,
};
use flowy_error::{FlowyError, FlowyResult};
use futures_util::{stream, FutureExt, StreamExt};
use lib_infra::async_trait::async_trait;
use lib_infra::util::timestamp;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use uuid::Uuid;

pub struct LocalServerChatServiceImpl {
  pub user: Arc<dyn ServerUser>,
  pub local_ai: Arc<LocalAIController>,
}

impl LocalServerChatServiceImpl {
  fn get_message_content(&self, message_id: i64) -> FlowyResult<String> {
    let uid = self.user.user_id()?;
    let db = self.user.get_sqlite_db(uid)?;
    let content = select_message_content(db, message_id)?.ok_or_else(|| {
      FlowyError::record_not_found().with_context(format!("Message not found: {}", message_id))
    })?;
    Ok(content)
  }
}

#[async_trait]
impl ChatCloudService for LocalServerChatServiceImpl {
  async fn create_chat(
    &self,
    _uid: &i64,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
    name: &str,
    metadata: Value,
  ) -> Result<(), FlowyError> {
    let uid = self.user.user_id()?;
    let db = self.user.get_sqlite_db(uid)?;

    let rag_ids = rag_ids
      .iter()
      .map(|v| v.to_string())
      .collect::<Vec<String>>();

    let row = ChatTable {
      chat_id: chat_id.to_string(),
      created_at: timestamp(),
      name: name.to_string(),
      metadata: serialize_chat_metadata(&metadata),
      rag_ids: Some(serialize_rag_ids(&rag_ids)),
    };

    upsert_chat(db, &row)?;
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
    chat_id: &Uuid,
    message_id: i64,
    format: ResponseFormat,
    _ai_model: Option<AIModel>,
  ) -> Result<StreamAnswer, FlowyError> {
    if self.local_ai.is_running() {
      let content = self.get_message_content(message_id)?;
      match self
        .local_ai
        .stream_question(
          &chat_id.to_string(),
          &content,
          Some(json!(format)),
          json!({}),
        )
        .await
      {
        Ok(stream) => Ok(QuestionStream::new(stream).boxed()),
        Err(err) => Ok(
          stream::once(async { Err(FlowyError::local_ai_unavailable().with_context(err)) }).boxed(),
        ),
      }
    } else {
      Err(FlowyError::local_ai_not_ready())
    }
  }

  async fn get_answer(
    &self,
    _workspace_id: &Uuid,
    _chat_id: &Uuid,
    _question_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_chat_messages(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    let uid = self.user.user_id()?;
    let db = self.user.get_sqlite_db(uid)?;

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
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    let chat_id = chat_id.to_string();
    let uid = self.user.user_id()?;
    let db = self.user.get_sqlite_db(uid)?;
    let row = read_chat(db, &chat_id)?;
    let rag_ids = deserialize_rag_ids(&row.rag_ids);
    let metadata = deserialize_chat_metadata::<serde_json::Value>(&row.metadata);
    let setting = ChatSettings {
      name: row.name,
      rag_ids,
      metadata,
    };

    Ok(setting)
  }

  async fn update_chat_settings(
    &self,
    _workspace_id: &Uuid,
    id: &Uuid,
    s: UpdateChatParams,
  ) -> Result<(), FlowyError> {
    let uid = self.user.user_id()?;
    let mut db = self.user.get_sqlite_db(uid)?;
    let changeset = ChatTableChangeset {
      chat_id: id.to_string(),
      name: s.name,
      metadata: s.metadata.map(|s| serialize_chat_metadata(&s)),
      rag_ids: s.rag_ids.map(|s| serialize_rag_ids(&s)),
    };

    update_chat(&mut db, changeset)?;
    Ok(())
  }

  async fn get_available_models(&self, _workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }

  async fn get_workspace_default_model(&self, _workspace_id: &Uuid) -> Result<String, FlowyError> {
    Err(FlowyError::not_support().with_context("Chat is not supported in local server."))
  }
}
