use std::sync::Arc;

use collab_document::YrsDocAction;
use collab_plugins::cloud_storage::RemoteCollabStorage;
use parking_lot::RwLock;
use tokio::sync::mpsc;

use flowy_database2::deps::DatabaseCloudService;
use flowy_document2::deps::DocumentCloudService;
use flowy_error::FlowyError;
use flowy_folder2::deps::FolderCloudService;
use flowy_user::entities::UserProfile;
use flowy_user::event_map::{UserService, UserWorkspace};
use flowy_user::services::database::{
  get_user_profile, get_user_workspace, open_collab_db, open_user_db,
};

use crate::local_server::impls::{
  LocalServerDatabaseCloudServiceImpl, LocalServerDocumentCloudServiceImpl,
  LocalServerFolderCloudServiceImpl, LocalServerUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub trait LocalServerDB: Send + Sync + 'static {
  fn get_user_profile(&self, uid: i64) -> Result<Option<UserProfile>, FlowyError>;
  fn get_user_workspace(&self, uid: i64) -> Result<Option<UserWorkspace>, FlowyError>;
  fn get_collab_updates(&self, uid: i64, object_id: &str) -> Result<Vec<Vec<u8>>, FlowyError>;
}

pub struct LocalServer {
  storage_path: String,
  stop_tx: RwLock<Option<mpsc::Sender<()>>>,
}

impl LocalServer {
  pub fn new(storage_path: &str) -> Self {
    Self {
      storage_path: storage_path.to_string(),
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
  fn user_service(&self) -> Arc<dyn UserService> {
    let db = LocalServerDBImpl {
      storage_path: self.storage_path.clone(),
    };
    Arc::new(LocalServerUserAuthServiceImpl { db: Arc::new(db) })
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    let db = LocalServerDBImpl {
      storage_path: self.storage_path.clone(),
    };
    Arc::new(LocalServerFolderCloudServiceImpl { db: Arc::new(db) })
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(LocalServerDatabaseCloudServiceImpl())
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(LocalServerDocumentCloudServiceImpl())
  }

  fn collab_storage(&self) -> Option<Arc<dyn RemoteCollabStorage>> {
    None
  }
}

struct LocalServerDBImpl {
  storage_path: String,
}

impl LocalServerDB for LocalServerDBImpl {
  fn get_user_profile(&self, uid: i64) -> Result<Option<UserProfile>, FlowyError> {
    let sqlite_db = open_user_db(&self.storage_path, uid)?;
    let user_profile = get_user_profile(&sqlite_db, uid).ok();
    Ok(user_profile)
  }

  fn get_user_workspace(&self, uid: i64) -> Result<Option<UserWorkspace>, FlowyError> {
    let sqlite_db = open_user_db(&self.storage_path, uid)?;
    let user_workspace = get_user_workspace(&sqlite_db, uid)?;
    Ok(user_workspace)
  }

  fn get_collab_updates(&self, uid: i64, object_id: &str) -> Result<Vec<Vec<u8>>, FlowyError> {
    let collab_db = open_collab_db(&self.storage_path, uid)?;
    let read_txn = collab_db.read_txn();
    let updates = read_txn
      .get_all_updates(uid, object_id)
      .map_err(|e| FlowyError::internal().context(format!("Failed to open collab db: {:?}", e)))?;

    Ok(updates)
  }
}
