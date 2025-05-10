pub mod chains;
mod format_prompt;
pub mod llm;
pub mod llm_chat;
pub mod retriever;
mod summary_memory;

use crate::local_ai::chat::chains::related_question_chain::RelatedQuestionChain;
use crate::local_ai::chat::llm::LLMOllama;
use crate::local_ai::chat::llm_chat::LLMChat;
use crate::local_ai::chat::retriever::MultipleSourceRetrieverStore;
use crate::local_ai::completion::chain::CompletionChain;
use crate::local_ai::database::summary::DatabaseSummaryChain;
use crate::local_ai::database::translate::DatabaseTranslateChain;
use crate::SqliteVectorStore;
use dashmap::{DashMap, Entry};
use flowy_ai_pub::cloud::ai_dto::{TranslateRowData, TranslateRowResponse};
use flowy_ai_pub::cloud::chat_dto::ChatAuthorType;
use flowy_ai_pub::cloud::{
  CompleteTextParams, CompletionType, ResponseFormat, StreamAnswer, StreamComplete,
};
use flowy_ai_pub::persistence::select_latest_user_message;
use flowy_ai_pub::user_service::AIUserService;
use flowy_database_pub::cloud::{SummaryRowContent, TranslateRowContent};
use flowy_error::{FlowyError, FlowyResult};
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

pub struct LLMChatInfo {
  pub chat_id: Uuid,
  pub workspace_id: Uuid,
  pub model: String,
  pub rag_ids: Vec<String>,
  pub summary: String,
}

pub type RetrieversSources = RwLock<Vec<Arc<dyn MultipleSourceRetrieverStore>>>;

pub struct LLMChatController {
  chat_by_id: DashMap<Uuid, LLMChat>,
  store: RwLock<Option<SqliteVectorStore>>,
  client: OllamaClientRef,
  user_service: Weak<dyn AIUserService>,
  retriever_sources: RetrieversSources,
}
impl LLMChatController {
  pub fn new(user_service: Weak<dyn AIUserService>) -> Self {
    Self {
      store: RwLock::new(None),
      chat_by_id: DashMap::new(),
      client: Default::default(),
      user_service,
      retriever_sources: Default::default(),
    }
  }

  pub async fn set_retriever_sources(&self, sources: Vec<Arc<dyn MultipleSourceRetrieverStore>>) {
    *self.retriever_sources.write().await = sources;
  }

  pub async fn is_ready(&self) -> bool {
    self.client.read().await.is_some()
  }

  #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
  pub async fn initialize(
    &self,
    ollama: Weak<Ollama>,
    vector_db: Weak<flowy_sqlite_vec::db::VectorSqliteDB>,
  ) {
    let store = SqliteVectorStore::new(ollama.clone(), vector_db);
    *self.client.write().await = Some(ollama);
    *self.store.write().await = Some(store);
  }

  pub fn set_rag_ids(&self, chat_id: &Uuid, rag_ids: &[String]) {
    if let Some(mut chat) = self.chat_by_id.get_mut(chat_id) {
      chat.set_rag_ids(rag_ids.to_vec());
    }
  }

  async fn create_chat_if_not_exist(&self, info: LLMChatInfo) -> FlowyResult<()> {
    debug_assert!(!self.retriever_sources.read().await.is_empty());

    let store = self.store.read().await.clone();
    let client = self
      .client
      .read()
      .await
      .as_ref()
      .ok_or_else(|| FlowyError::local_ai().with_context("Ollama client not initialized"))?
      .upgrade()
      .ok_or_else(|| FlowyError::local_ai().with_context("Ollama client has been dropped"))?
      .clone();
    let entry = self.chat_by_id.entry(info.chat_id);
    let retriever_sources = self
      .retriever_sources
      .read()
      .await
      .iter()
      .map(Arc::downgrade)
      .collect();
    if let Entry::Vacant(e) = entry {
      let chat = LLMChat::new(
        info,
        client,
        store,
        Some(self.user_service.clone()),
        retriever_sources,
      )?;
      e.insert(chat);
    }
    Ok(())
  }

  pub async fn open_chat(&self, info: LLMChatInfo) -> FlowyResult<()> {
    let _ = self.create_chat_if_not_exist(info).await;
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
    model_name: &str,
  ) -> FlowyResult<StreamAnswer> {
    if let Some(mut chat) = self.chat_by_id.get_mut(chat_id) {
      chat.set_chat_model(model_name);

      let response = chat.stream_question(question, format).await;
      return response;
    }

    Err(FlowyError::local_ai().with_context(format!("Chat with id {} not found", chat_id)))
  }
}
