use flowy_search_pub::cloud::SearchCloudService;
use std::sync::Arc;

use parking_lot::RwLock;
use tokio::sync::mpsc;

use flowy_database_pub::cloud::{DatabaseAIService, DatabaseCloudService};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_error::FlowyError;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_storage_pub::cloud::StorageCloudService;
// use flowy_user::services::database::{
//   get_user_profile, get_user_workspace, open_collab_db, open_user_db,
// };
use flowy_user_pub::cloud::UserCloudService;
use flowy_user_pub::entities::*;

use crate::local_server::impls::{
  LocalServerDatabaseCloudServiceImpl, LocalServerDocumentCloudServiceImpl,
  LocalServerFolderCloudServiceImpl, LocalServerUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub trait LocalServerDB: Send + Sync + 'static {
  fn get_user_profile(&self, uid: i64) -> Result<UserProfile, FlowyError>;
  fn get_user_workspace(&self, uid: i64) -> Result<Option<UserWorkspace>, FlowyError>;
}

pub struct LocalServer {
  local_db: Arc<dyn LocalServerDB>,
  stop_tx: RwLock<Option<mpsc::Sender<()>>>,
}

impl LocalServer {
  pub fn new(local_db: Arc<dyn LocalServerDB>) -> Self {
    Self {
      local_db,
      stop_tx: Default::default(),
    }
  }

  pub async fn stop(&self) {
    let sender = self.stop_tx.read().clone();
    if let Some(stop_tx) = sender {
      let _ = stop_tx.send(()).await;
    }
  }
}

impl AppFlowyServer for LocalServer {
  fn user_service(&self) -> Arc<dyn UserCloudService> {
    Arc::new(LocalServerUserAuthServiceImpl {
      db: self.local_db.clone(),
    })
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(LocalServerFolderCloudServiceImpl {
      db: self.local_db.clone(),
    })
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(LocalServerDatabaseCloudServiceImpl())
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(LocalServerDocumentCloudServiceImpl())
  }

  fn file_storage(&self) -> Option<Arc<dyn StorageCloudService>> {
    None
  }

  fn search_service(&self) -> Option<Arc<dyn SearchCloudService>> {
    None
  }

  fn database_ai_service(&self) -> Option<Arc<dyn DatabaseAIService>> {
    None
  }
}
