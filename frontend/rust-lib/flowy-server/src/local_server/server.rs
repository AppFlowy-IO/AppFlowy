use flowy_search_pub::cloud::SearchCloudService;
use std::sync::Arc;

use crate::af_cloud::define::LoggedUser;
use crate::local_server::impls::{
  LocalChatServiceImpl, LocalServerDatabaseCloudServiceImpl, LocalServerDocumentCloudServiceImpl,
  LocalServerFolderCloudServiceImpl, LocalServerUserServiceImpl,
};
use crate::AppFlowyServer;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_ai_pub::cloud::ChatCloudService;
use flowy_database_pub::cloud::{DatabaseAIService, DatabaseCloudService};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_storage_pub::cloud::StorageCloudService;
use flowy_user_pub::cloud::UserCloudService;
use tokio::sync::mpsc;

pub struct LocalServer {
  user: Arc<dyn LoggedUser>,
  local_ai: Arc<LocalAIController>,
  stop_tx: Option<mpsc::Sender<()>>,
}

impl LocalServer {
  pub fn new(user: Arc<dyn LoggedUser>, local_ai: Arc<LocalAIController>) -> Self {
    Self {
      user,
      local_ai,
      stop_tx: Default::default(),
    }
  }

  pub async fn stop(&self) {
    let sender = self.stop_tx.clone();
    if let Some(stop_tx) = sender {
      let _ = stop_tx.send(()).await;
    }
  }
}

impl AppFlowyServer for LocalServer {
  fn user_service(&self) -> Arc<dyn UserCloudService> {
    Arc::new(LocalServerUserServiceImpl {
      user: self.user.clone(),
    })
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(LocalServerFolderCloudServiceImpl)
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(LocalServerDatabaseCloudServiceImpl())
  }

  fn database_ai_service(&self) -> Option<Arc<dyn DatabaseAIService>> {
    None
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(LocalServerDocumentCloudServiceImpl())
  }

  fn chat_service(&self) -> Arc<dyn ChatCloudService> {
    Arc::new(LocalChatServiceImpl {
      user: self.user.clone(),
      local_ai: self.local_ai.clone(),
    })
  }

  fn search_service(&self) -> Option<Arc<dyn SearchCloudService>> {
    None
  }

  fn file_storage(&self) -> Option<Arc<dyn StorageCloudService>> {
    None
  }
}
