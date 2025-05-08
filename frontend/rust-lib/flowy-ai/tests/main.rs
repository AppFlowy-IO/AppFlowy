mod chat_test;
mod complete_test;
mod summary_test;
mod translate_test;

use flowy_ai::local_ai::chat::llm_chat::LLMChat;
use flowy_ai::local_ai::chat::LLMChatInfo;
use flowy_ai::SqliteVectorStore;
use flowy_sqlite_vec::db::VectorSqliteDB;
use langchain_rust::url::Url;
use ollama_rs::Ollama;
use std::sync::{Arc, Once};
use tempfile::tempdir;
use tokio::sync::RwLock;
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
    std::env::set_var("RUST_LOG", filters.join(","));

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
    let ollama_client = Arc::new(RwLock::new(Some(Arc::downgrade(&self.ollama))));
    let info = LLMChatInfo {
      chat_id,
      workspace_id,
      model: model.to_string(),
      rag_ids: rag_ids.clone(),
      summary: "".to_string(),
    };

    LLMChat::new(info, ollama_client, Some(self.store.clone()), None)
      .await
      .unwrap()
  }
}
