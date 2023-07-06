use std::sync::Arc;

use appflowy_integrate::RemoteCollabStorage;
use parking_lot::RwLock;
use tokio::sync::mpsc;

use flowy_database2::deps::DatabaseCloudService;
use flowy_document2::deps::DocumentCloudService;
use flowy_folder2::deps::FolderCloudService;
use flowy_user::event_map::UserAuthService;

use crate::local_server::impls::{
  LocalServerDatabaseCloudServiceImpl, LocalServerDocumentCloudServiceImpl,
  LocalServerFolderCloudServiceImpl, LocalServerUserAuthServiceImpl,
};
use crate::AppFlowyServer;

#[derive(Default)]
pub struct LocalServer {
  stop_tx: RwLock<Option<mpsc::Sender<()>>>,
}

impl LocalServer {
  pub fn new() -> Self {
    // let _config = self_host_server_configuration().unwrap();
    Self::default()
  }

  pub async fn stop(&self) {
    let sender = self.stop_tx.read().clone();
    if let Some(stop_tx) = sender {
      let _ = stop_tx.send(()).await;
    }
  }
}

impl AppFlowyServer for LocalServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(LocalServerUserAuthServiceImpl())
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(LocalServerFolderCloudServiceImpl())
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
