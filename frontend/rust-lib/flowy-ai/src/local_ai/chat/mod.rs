mod conversation_chain;
pub mod llm;
pub mod llm_chat;
pub mod related_question_chain;

use crate::embeddings::store::SqliteVectorStore;
use crate::local_ai::chat::llm::LLMOllama;
use crate::local_ai::chat::llm_chat::LLMChat;
use crate::local_ai::chat::related_question_chain::RelatedQuestionChain;
use crate::local_ai::completion::chain::CompletionChain;
use crate::local_ai::database::summary::DatabaseSummaryChain;
use crate::local_ai::database::translate::DatabaseTranslateChain;
use dashmap::DashMap;
use flowy_ai_pub::cloud::ai_dto::{TranslateRowData, TranslateRowResponse};
use flowy_ai_pub::cloud::chat_dto::ChatAuthorType;
use flowy_ai_pub::cloud::{
  CompleteTextParams, CompletionType, ResponseFormat, StreamAnswer, StreamComplete,
};
use flowy_ai_pub::persistence::select_latest_user_message;
use flowy_ai_pub::user_service::AIUserService;
use flowy_database_pub::cloud::{SummaryRowContent, TranslateRowContent};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite_vec::db::VectorSqliteDB;
use futures_util::StreamExt;
use ollama_rs::Ollama;
use serde_json::Value;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::trace;
use uuid::Uuid;

type OllamaClientRef = Arc<RwLock<Option<Weak<Ollama>>>>;

pub struct LLMChatController {
  chat_by_id: DashMap<Uuid, LLMChat>,
  store: RwLock<Option<SqliteVectorStore>>,
  client: OllamaClientRef,
  user_service: Weak<dyn AIUserService>,
}
impl LLMChatController {
  pub fn new(user_service: Weak<dyn AIUserService>) -> Self {
    Self {
      store: RwLock::new(None),
      chat_by_id: DashMap::new(),
      client: Default::default(),
      user_service,
    }
  }

  pub async fn is_ready(&self) -> bool {
    self.client.read().await.is_some()
  }

  pub async fn initialize(&self, ollama: Weak<Ollama>, vector_db: Weak<VectorSqliteDB>) {
    let store = SqliteVectorStore::new(ollama.clone(), vector_db);
    *self.client.write().await = Some(ollama);
    *self.store.write().await = Some(store);
  }

  pub async fn open_chat(
    &self,
    workspace_id: &Uuid,
    chat_id: &Uuid,
    model: &str,
  ) -> FlowyResult<()> {
    let store = self.store.read().await.clone();
    let chat = LLMChat::new(
      *workspace_id,
      *chat_id,
      model,
      self.client.clone(),
      store,
      vec![],
    )
    .await?;
    self.chat_by_id.insert(*chat_id, chat);
    Ok(())
  }

  pub fn close_chat(&self, chat_id: &Uuid) {
    self.chat_by_id.remove(chat_id);
  }

  pub async fn summarize_database_row(
    &self,
    model_name: &str,
    data: SummaryRowContent,
  ) -> FlowyResult<String> {
    let client = self
      .client
      .read()
      .await
      .clone()
      .ok_or(FlowyError::local_ai())?
      .upgrade()
      .ok_or(FlowyError::local_ai())?;

    let chain = DatabaseSummaryChain::new(LLMOllama::new(model_name, client, None, None));
    let response = chain.summarize(data).await?;
    Ok(response)
  }

  pub async fn translate_database_row(
    &self,
    model_name: &str,
    cells: TranslateRowContent,
    language: &str,
  ) -> FlowyResult<TranslateRowResponse> {
    let client = self
      .client
      .read()
      .await
      .clone()
      .ok_or(FlowyError::local_ai())?
      .upgrade()
      .ok_or(FlowyError::local_ai())?;

    let chain = DatabaseTranslateChain::new(LLMOllama::new(model_name, client, None, None));
    let data = TranslateRowData {
      cells,
      language: language.to_string(),
      include_header: false,
    };
    let resp = chain.translate(data).await?;
    Ok(resp)
  }

  pub async fn complete_text(
    &self,
    model_name: &str,
    params: CompleteTextParams,
  ) -> Result<StreamComplete, FlowyError> {
    let client = self
      .client
      .read()
      .await
      .clone()
      .ok_or(FlowyError::local_ai())?
      .upgrade()
      .ok_or(FlowyError::local_ai())?;

    let chain = CompletionChain::new(LLMOllama::new(model_name, client, None, None));
    let ty = params.completion_type.unwrap_or(CompletionType::AskAI);
    let stream = chain
      .complete(&params.text, ty, params.format, params.metadata)
      .await?
      .boxed();
    Ok(stream)
  }

  pub async fn embed_file(
    &self,
    _chat_id: &Uuid,
    _file_path: PathBuf,
    _metadata: Option<HashMap<String, Value>>,
  ) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn get_related_question(
    &self,
    model_name: &str,
    chat_id: &Uuid,
    _message_id: i64,
  ) -> FlowyResult<Vec<String>> {
    let client = self
      .client
      .read()
      .await
      .clone()
      .ok_or(FlowyError::local_ai())?
      .upgrade()
      .ok_or(FlowyError::local_ai())?;

    let user_service = self.user_service.upgrade().ok_or(FlowyError::local_ai())?;
    let uid = user_service.user_id()?;
    let conn = user_service.sqlite_connection(uid)?;
    let message = select_latest_user_message(conn, &chat_id.to_string(), ChatAuthorType::Human)?;

    let chain = RelatedQuestionChain::new(LLMOllama::new(model_name, client, None, None));
    let questions = chain.related_question(&message.content).await?;
    trace!(
      "related questions: {:?} for message: {}",
      questions,
      message.content
    );
    Ok(questions)
  }

  pub async fn ask_question(&self, chat_id: &Uuid, question: &str) -> FlowyResult<String> {
    if let Some(chat) = self.chat_by_id.get(chat_id) {
      let chat = chat.value();
      let response = chat.ask_question(question).await;
      return response;
    }

    Err(FlowyError::local_ai().with_context(format!("Chat with id {} not found", chat_id)))
  }

  pub async fn stream_question(
    &self,
    chat_id: &Uuid,
    question: &str,
    format: ResponseFormat,
  ) -> FlowyResult<StreamAnswer> {
    if let Some(mut chat) = self.chat_by_id.get_mut(chat_id) {
      let response = chat.stream_question(question, format).await;
      return response;
    }

    Err(FlowyError::local_ai().with_context(format!("Chat with id {} not found", chat_id)))
  }
}
