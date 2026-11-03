use crate::embeddings::scheduler::EmbeddingScheduler;
use crate::local_ai::client::AIClient;
use arc_swap::ArcSwapOption;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite_vec::db::VectorSqliteDB;
use lib_infra::util::get_operating_system;
use std::path::PathBuf;
use std::sync::{Arc, OnceLock};
use tracing::{error, info, warn};

pub struct EmbedContext {
  client: ArcSwapOption<AIClient>,
  /// Embedding model name for the active client. Provider-specific, so it travels with the client.
  embedding_model: ArcSwapOption<String>,
  vector_db: ArcSwapOption<VectorSqliteDB>,
  scheduler: ArcSwapOption<EmbeddingScheduler>,
}

impl EmbedContext {
  pub fn shared() -> &'static Arc<EmbedContext> {
    static INSTANCE: OnceLock<Arc<EmbedContext>> = OnceLock::new();
    INSTANCE.get_or_init(|| {
      Arc::new(EmbedContext {
        client: ArcSwapOption::empty(),
        embedding_model: ArcSwapOption::empty(),
        vector_db: ArcSwapOption::empty(),
        scheduler: Default::default(),
      })
    })
  }

  pub fn get_vector_db(&self) -> Option<Arc<VectorSqliteDB>> {
    self.vector_db.load_full()
  }

  pub fn init_vector_db(&self, db_path: PathBuf) {
    let sys = get_operating_system();
    if !sys.is_desktop() {
      warn!("[Embedding] Vector db is not supported on {:?}", sys);
      return;
    }

    info!("Initializing vector db");
    match VectorSqliteDB::new(db_path.clone()) {
      Ok(db) => {
        info!("[Embedding] Vector db created at: {:?}", db_path);
        self.vector_db.store(Some(Arc::new(db)));
        self.try_create_scheduler();
      },
      Err(err) => {
        error!("[Embedding] Failed to create vector db: {}", err);
      },
    }
  }

  pub fn set_client(&self, client: Option<Arc<AIClient>>, embedding_model: &str) {
    if let Some(client) = client {
      let unchanged = self
        .client
        .load()
        .as_ref()
        .is_some_and(|c| c.same_as(&client))
        && self
          .embedding_model
          .load()
          .as_ref()
          .is_some_and(|m| m.as_str() == embedding_model);
      if unchanged {
        info!("[Embedding] ai client does not change");
        return;
      }

      self.client.store(Some(client));
      self
        .embedding_model
        .store(Some(Arc::new(embedding_model.to_string())));
      self.try_create_scheduler();
    } else {
      self.client.store(None);
      self.embedding_model.store(None);
      if let Some(s) = self.scheduler.swap(None) {
        info!("[Embedding] Stopping scheduler");
        let _ = s.stop_tx.send(());
      }
    }
  }

  pub fn get_scheduler(&self) -> FlowyResult<Arc<EmbeddingScheduler>> {
    self.scheduler.load_full().ok_or_else(|| {
      FlowyError::new(
        ErrorCode::LocalEmbeddingNotReady,
        "Local embedding is not ready. Please check if the Ollama and vector db are initialized.",
      )
    })
  }

  fn try_create_scheduler(&self) {
    if let (Some(client), Some(model), Some(vector_db)) = (
      self.client.load_full(),
      self.embedding_model.load_full(),
      self.vector_db.load_full(),
    ) {
      info!("[Embedding] Creating scheduler");
      match EmbeddingScheduler::new(client, model.to_string(), vector_db) {
        Ok(s) => {
          info!("[Embedding] create scheduler successfully");
          self.scheduler.store(Some(s));
        },
        Err(err) => error!("[Embedding] Failed to create scheduler: {}", err),
      }
    } else {
      info!("[Embedding] ai client or vector db is not initialized, remove embedding scheduler");
      self.scheduler.store(None);
    }
  }
}
