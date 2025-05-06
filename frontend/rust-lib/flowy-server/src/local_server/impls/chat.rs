use crate::af_cloud::define::LoggedUser;
use crate::local_server::uid::IDGenerator;
use chrono::{TimeZone, Utc};
use client_api::entity::ai_dto::RepeatedRelatedQuestion;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_ai_pub::cloud::chat_dto::{ChatAuthor, ChatAuthorType};
use flowy_ai_pub::cloud::{
  AIModel, ChatCloudService, ChatMessage, ChatMessageType, ChatSettings, CompleteTextParams,
  MessageCursor, ModelList, RelatedQuestion, RepeatedChatMessage, ResponseFormat, StreamAnswer,
  StreamComplete, UpdateChatParams, DEFAULT_AI_MODEL_NAME,
};
use flowy_ai_pub::persistence::{
  deserialize_chat_metadata, deserialize_rag_ids, read_chat,
  select_answer_where_match_reply_message_id, select_chat_messages, select_message_content,
  serialize_chat_metadata, serialize_rag_ids, update_chat, upsert_chat, upsert_chat_messages,
  ChatMessageTable, ChatTable, ChatTableChangeset,
};
use flowy_error::{FlowyError, FlowyResult};
use lazy_static::lazy_static;
use lib_infra::async_trait::async_trait;
use lib_infra::util::timestamp;
use serde_json::{json, Value};
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::trace;
use uuid::Uuid;

lazy_static! {
  static ref ID_GEN: Mutex<IDGenerator> = Mutex::new(IDGenerator::new(2));
}

pub struct LocalChatServiceImpl {
  pub logged_user: Arc<dyn LoggedUser>,
  pub local_ai: Arc<LocalAIController>,
}

impl LocalChatServiceImpl {
  fn get_message_content(&self, message_id: i64) -> FlowyResult<String> {
    let uid = self.logged_user.user_id()?;
    let db = self.logged_user.get_sqlite_db(uid)?;
    let content = select_message_content(db, message_id)?.ok_or_else(|| {
      FlowyError::record_not_found().with_context(format!("Message not found: {}", message_id))
    })?;
    Ok(content)
  }

  async fn upsert_message(&self, chat_id: &Uuid, message: ChatMessage) -> Result<(), FlowyError> {
    let uid = self.logged_user.user_id()?;
    let conn = self.logged_user.get_sqlite_db(uid)?;
    let row = ChatMessageTable::from_message(chat_id.to_string(), message, true);
    upsert_chat_messages(conn, &[row])?;
    Ok(())
  }
}

#[async_trait]
impl ChatCloudService for LocalChatServiceImpl {
  async fn create_chat(
    &self,
    _uid: &i64,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    rag_ids: Vec<Uuid>,
    _name: &str,
    metadata: Value,
  ) -> Result<(), FlowyError> {
    let uid = self.logged_user.user_id()?;
    let db = self.logged_user.get_sqlite_db(uid)?;
    let row = ChatTable::new(chat_id.to_string(), metadata, rag_ids, true);
    upsert_chat(db, &row)?;
    Ok(())
  }

  async fn create_question(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    message_type: ChatMessageType,
  ) -> Result<ChatMessage, FlowyError> {
    let message_id = ID_GEN.lock().await.next_id();
    let message = match message_type {
      ChatMessageType::System => ChatMessage::new_system(message_id, message.to_string()),
      ChatMessageType::User => ChatMessage::new_human(message_id, message.to_string(), None),
    };

    self.upsert_message(chat_id, message.clone()).await?;
    Ok(message)
  }

  async fn create_answer(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    message: &str,
    question_id: i64,
    metadata: Option<serde_json::Value>,
  ) -> Result<ChatMessage, FlowyError> {
    let mut message = ChatMessage::new_ai(timestamp(), message.to_string(), Some(question_id));
    if let Some(metadata) = metadata {
      message.metadata = metadata;
    }
    self.upsert_message(chat_id, message.clone()).await?;
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
    if self.local_ai.is_ready().await {
      let content = self.get_message_content(message_id)?;
      self
        .local_ai
        .stream_question(chat_id, &content, format)
        .await
    } else {
      Err(FlowyError::local_ai_disabled())
    }
  }

  async fn get_answer(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    question_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let uid = self.logged_user.user_id()?;
    let db = self.logged_user.get_sqlite_db(uid)?;

    match select_answer_where_match_reply_message_id(db, &chat_id.to_string(), question_id)? {
      None => Err(FlowyError::record_not_found()),
      Some(message) => Ok(chat_message_from_row(message)),
    }
  }

  async fn get_chat_messages(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    offset: MessageCursor,
    limit: u64,
  ) -> Result<RepeatedChatMessage, FlowyError> {
    let chat_id = chat_id.to_string();
    let uid = self.logged_user.user_id()?;
    let db = self.logged_user.get_sqlite_db(uid)?;
    let result = select_chat_messages(db, &chat_id, limit, offset)?;

    let messages = result
      .messages
      .into_iter()
      .map(chat_message_from_row)
      .collect();

    Ok(RepeatedChatMessage {
      messages,
      has_more: result.has_more,
      total: result.total_count,
    })
  }

  async fn get_question_from_answer_id(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    answer_message_id: i64,
  ) -> Result<ChatMessage, FlowyError> {
    let chat_id = chat_id.to_string();
    let uid = self.logged_user.user_id()?;
    let db = self.logged_user.get_sqlite_db(uid)?;
    let row = select_answer_where_match_reply_message_id(db, &chat_id, answer_message_id)?
      .map(chat_message_from_row)
      .ok_or_else(FlowyError::record_not_found)?;
    Ok(row)
  }

  async fn get_related_message(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
    message_id: i64,
    ai_model: AIModel,
  ) -> Result<RepeatedRelatedQuestion, FlowyError> {
    if self.local_ai.is_ready().await {
      let questions = self
        .local_ai
        .get_related_question(&ai_model.name, chat_id, message_id)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;
      trace!("LocalAI related questions: {:?}", questions);

      let items = questions
        .into_iter()
        .map(|content| RelatedQuestion {
          content,
          metadata: None,
        })
        .collect::<Vec<_>>();

      Ok(RepeatedRelatedQuestion { message_id, items })
    } else {
      Ok(RepeatedRelatedQuestion {
        message_id,
        items: vec![],
      })
    }
  }

  async fn stream_complete(
    &self,
    _workspace_id: &Uuid,
    params: CompleteTextParams,
    ai_model: AIModel,
  ) -> Result<StreamComplete, FlowyError> {
    if self.local_ai.is_ready().await {
      self.local_ai.complete_text(&ai_model.name, params).await
    } else {
      Err(FlowyError::local_ai_disabled())
    }
  }

  async fn embed_file(
    &self,
    _workspace_id: &Uuid,
    file_path: &Path,
    chat_id: &Uuid,
    metadata: Option<HashMap<String, Value>>,
  ) -> Result<(), FlowyError> {
    if self.local_ai.is_ready().await {
      self
        .local_ai
        .embed_file(chat_id, file_path.to_path_buf(), metadata)
        .await
        .map_err(|err| FlowyError::local_ai().with_context(err))?;
      Ok(())
    } else {
      Err(FlowyError::local_ai_not_ready())
    }
  }

  async fn get_chat_settings(
    &self,
    _workspace_id: &Uuid,
    chat_id: &Uuid,
  ) -> Result<ChatSettings, FlowyError> {
    let chat_id = chat_id.to_string();
    let uid = self.logged_user.user_id()?;
    let db = self.logged_user.get_sqlite_db(uid)?;
    let row = read_chat(db, &chat_id)?;
    let rag_ids = deserialize_rag_ids(&row.rag_ids);
    let metadata = deserialize_chat_metadata::<Value>(&row.metadata);
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
    let uid = self.logged_user.user_id()?;
    let mut db = self.logged_user.get_sqlite_db(uid)?;
    let changeset = ChatTableChangeset {
      chat_id: id.to_string(),
      name: s.name,
      metadata: s.metadata.map(|s| serialize_chat_metadata(&s)),
      rag_ids: s.rag_ids.map(|s| serialize_rag_ids(&s)),
      is_sync: None,
    };

    update_chat(&mut db, changeset)?;
    Ok(())
  }

  async fn get_available_models(&self, _workspace_id: &Uuid) -> Result<ModelList, FlowyError> {
    Ok(ModelList { models: vec![] })
  }

  async fn get_workspace_default_model(&self, _workspace_id: &Uuid) -> Result<String, FlowyError> {
    Ok(DEFAULT_AI_MODEL_NAME.to_string())
  }

  async fn set_workspace_default_model(
    &self,
    _workspace_id: &Uuid,
    _model: &str,
  ) -> Result<(), FlowyError> {
    // do nothing
    Ok(())
  }
}

fn chat_message_from_row(row: ChatMessageTable) -> ChatMessage {
  let created_at = Utc
    .timestamp_opt(row.created_at, 0)
    .single()
    .unwrap_or_else(Utc::now);

  let author_id = row.author_id.parse::<i64>().unwrap_or_default();
  let author_type = match row.author_type {
    1 => ChatAuthorType::Human,
    2 => ChatAuthorType::System,
    3 => ChatAuthorType::AI,
    _ => ChatAuthorType::Unknown,
  };

  let metadata = row
    .metadata
    .map(|s| deserialize_chat_metadata::<Value>(&s))
    .unwrap_or_else(|| json!({}));

  ChatMessage {
    author: ChatAuthor {
      author_id,
      author_type,
      meta: None,
    },
    message_id: row.message_id,
    content: row.content,
    created_at,
    metadata,
    reply_message_id: row.reply_message_id,
  }
}
