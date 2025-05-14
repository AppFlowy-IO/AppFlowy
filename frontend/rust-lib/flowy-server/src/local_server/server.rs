use crate::af_cloud::define::LoggedUser;
use crate::local_server::impls::{
  LocalChatServiceImpl, LocalSearchServiceImpl, LocalServerDatabaseCloudServiceImpl,
  LocalServerDocumentCloudServiceImpl, LocalServerFolderCloudServiceImpl,
  LocalServerUserServiceImpl,
};
use crate::{AppFlowyServer, EmbeddingWriter};
use anyhow::Error;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_ai_pub::cloud::ChatCloudService;
use flowy_database_pub::cloud::{DatabaseAIService, DatabaseCloudService};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_search_pub::cloud::SearchCloudService;
use flowy_search_pub::tantivy_state::DocumentTantivyState;
use flowy_storage_pub::cloud::StorageCloudService;
use flowy_user_pub::cloud::UserCloudService;
use lib_infra::async_trait::async_trait;
use std::sync::{Arc, Weak};
use tokio::sync::{RwLock, mpsc};

pub struct LocalServer {
  logged_user: Arc<dyn LoggedUser>,
  local_ai: Arc<LocalAIController>,
  stop_tx: Option<mpsc::Sender<()>>,
  embedding_writer: Option<Arc<dyn EmbeddingWriter>>,
  tanvity_state: RwLock<Option<Weak<RwLock<DocumentTantivyState>>>>,
}

impl LocalServer {
  pub fn new(
    logged_user: Arc<dyn LoggedUser>,
    local_ai: Arc<LocalAIController>,
    embedding_writer: Option<Arc<dyn EmbeddingWriter>>,
  ) -> Self {
    Self {
      logged_user,
      local_ai,
      stop_tx: Default::default(),
      embedding_writer,
      tanvity_state: Default::default(),
    }
  }

  pub async fn stop(&self) {
    let sender = self.stop_tx.clone();
    if let Some(stop_tx) = sender {
      let _ = stop_tx.send(()).await;
    }
  }
}

#[async_trait]
impl AppFlowyServer for LocalServer {
  fn set_token(&self, _token: &str) -> Result<(), Error> {
    Ok(())
  }

  async fn set_tanvity_state(&self, state: Option<Weak<RwLock<DocumentTantivyState>>>) {
    *self.tanvity_state.write().await = state;
  }

  fn user_service(&self) -> Arc<dyn UserCloudService> {
    Arc::new(LocalServerUserServiceImpl {
      logged_user: self.logged_user.clone(),
    })
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(LocalServerFolderCloudServiceImpl {
      logged_user: self.logged_user.clone(),
      embedding_writer: self.embedding_writer.clone(),
    })
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(LocalServerDatabaseCloudServiceImpl {
      logged_user: self.logged_user.clone(),
    })
  }

  fn database_ai_service(&self) -> Option<Arc<dyn DatabaseAIService>> {
    None
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(LocalServerDocumentCloudServiceImpl())
  }

  fn chat_service(&self) -> Arc<dyn ChatCloudService> {
    Arc::new(LocalChatServiceImpl {
      logged_user: self.logged_user.clone(),
      local_ai: self.local_ai.clone(),
    })
  }

  async fn search_service(&self) -> Option<Arc<dyn SearchCloudService>> {
    let state = self.tanvity_state.read().await.clone();
    Some(Arc::new(LocalSearchServiceImpl {
      logged_user: self.logged_user.clone(),
      local_ai: self.local_ai.clone(),
      state,
    }))
  }

  fn file_storage(&self) -> Option<Arc<dyn StorageCloudService>> {
    None
  }
}
