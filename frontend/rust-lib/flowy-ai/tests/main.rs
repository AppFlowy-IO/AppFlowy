mod chat_test;
mod complete_test;
mod summary_test;
mod translate_test;

use flowy_ai::local_ai::chat::llm_chat::LLMChat;
use flowy_ai::local_ai::chat::LLMChatInfo;
use flowy_ai::SqliteVectorStore;
use flowy_ai_pub::cloud::{ContextSuggestedQuestion, QuestionStreamValue, StreamAnswer};
use flowy_sqlite_vec::db::VectorSqliteDB;
use langchain_rust::url::Url;
use ollama_rs::Ollama;
use serde_json::Value;
use std::sync::{Arc, Once};
use tempfile::tempdir;
use tokio_stream::StreamExt;
use tracing_subscriber::fmt::Subscriber;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;
use uuid::Uuid;

pub fn setup_log() {
  static START: Once = Once::new();
  START.call_once(|| {
    let level = std::env::var("RUST_LOG").unwrap_or("trace".to_string());
    let mut filters = vec![];
    filters.push(format!("flowy_ai={}", level));
    unsafe {
      std::env::set_var("RUST_LOG", filters.join(","));
    }

    let subscriber = Subscriber::builder()
      .with_ansi(true)
      .with_env_filter(EnvFilter::from_default_env())
      .finish();
    subscriber.try_init().unwrap();
  });
}

pub struct TestContext {
  ollama: Arc<Ollama>,
  store: SqliteVectorStore,
  #[allow(dead_code)]
  db: Arc<VectorSqliteDB>,
  #[allow(dead_code)]
  vector_store: SqliteVectorStore,
}

impl TestContext {
  pub fn new() -> anyhow::Result<Self> {
    setup_log();

    let ollama_url = "http://localhost:11434";
    let url = Url::parse(ollama_url)?;
    let ollama = Arc::new(Ollama::from_url(url.clone()));

    let temp_dir = tempdir()?;
    let db = Arc::new(VectorSqliteDB::new(temp_dir.into_path())?);
    let vector_store = SqliteVectorStore::new(Arc::downgrade(&ollama), Arc::downgrade(&db));

    Ok(Self {
      ollama,
      store: vector_store.clone(),
      db,
      vector_store,
    })
  }

  pub async fn create_chat(&self, rag_ids: Vec<String>) -> LLMChat {
    let workspace_id = Uuid::new_v4();
    let chat_id = Uuid::new_v4();
    let model = "llama3.1";
    let info = LLMChatInfo {
      chat_id,
      workspace_id,
      model: model.to_string(),
      rag_ids: rag_ids.clone(),
      summary: "".to_string(),
    };

    LLMChat::new(
      info,
      self.ollama.clone(),
      Some(self.store.clone()),
      None,
      vec![],
    )
    .unwrap()
  }
}

#[derive(Debug)]
pub struct StreamResult {
  pub answer: String,
  pub sources: Vec<Value>,
  pub suggested_questions: Vec<ContextSuggestedQuestion>,
  pub gen_related_question: bool,
}

pub async fn collect_stream(stream: StreamAnswer) -> StreamResult {
  let mut result = String::new();
  let mut sources = vec![];
  let mut gen_related_question = true;
  let mut suggested_questions = vec![];
  let mut stream = stream;
  while let Some(chunk) = stream.next().await {
    match chunk {
      Ok(value) => match value {
        QuestionStreamValue::Answer { value } => {
          result.push_str(&value);
        },
        QuestionStreamValue::Metadata { value } => {
          dbg!("metadata", &value);
          sources.push(value);
        },

        QuestionStreamValue::SuggestedQuestion {
          context_suggested_questions,
        } => {
          suggested_questions = context_suggested_questions;
        },
        QuestionStreamValue::FollowUp {
          should_generate_related_question,
        } => {
          gen_related_question = should_generate_related_question;
        },
      },
      Err(e) => {
        eprintln!("Error: {}", e);
      },
    }
  }

  StreamResult {
    answer: result,
    sources,
    suggested_questions,
    gen_related_question,
  }
}

pub fn load_asset_content(name: &str) -> String {
  let path = format!("tests/asset/{}", name);
  std::fs::read_to_string(path).unwrap_or_else(|_| {
    panic!("Failed to read asset file: {}", name);
  })
}
