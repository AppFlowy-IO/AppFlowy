use flowy_search_pub::cloud::SearchCloudService;
use std::sync::Arc;

use crate::af_cloud::define::ServerUser;
use crate::local_server::impls::{
  LocalServerChatServiceImpl, LocalServerDatabaseCloudServiceImpl,
  LocalServerDocumentCloudServiceImpl, LocalServerFolderCloudServiceImpl,
  LocalServerUserServiceImpl,
};
use crate::AppFlowyServer;
use flowy_ai_pub::cloud::ChatCloudService;
use flowy_database_pub::cloud::{DatabaseAIService, DatabaseCloudService};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_storage_pub::cloud::StorageCloudService;
use flowy_user_pub::cloud::UserCloudService;
use tokio::sync::mpsc;

pub struct LocalServer {
  user: Arc<dyn ServerUser>,
  stop_tx: Option<mpsc::Sender<()>>,
}

impl LocalServer {
  pub fn new(user: Arc<dyn ServerUser>) -> Self {
    Self {
      user,
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
    Arc::new(LocalServerUserServiceImpl)
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
    Arc::new(LocalServerChatServiceImpl {
      user: self.user.clone(),
    })
  }

  fn search_service(&self) -> Option<Arc<dyn SearchCloudService>> {
    None
  }

  fn file_storage(&self) -> Option<Arc<dyn StorageCloudService>> {
    None
  }
}
