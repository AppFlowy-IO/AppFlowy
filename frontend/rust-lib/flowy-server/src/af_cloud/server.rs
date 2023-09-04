use std::sync::Arc;

use collab_plugins::cloud_storage::{CollabObject, RemoteCollabStorage};

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_storage::FileStorageService;
use flowy_user_deps::cloud::UserCloudService;

use crate::af_cloud::configuration::AFCloudConfiguration;
use crate::af_cloud::impls::{
  AFCloudDatabaseCloudServiceImpl, AFCloudDocumentCloudServiceImpl, AFCloudFolderCloudServiceImpl,
  AFCloudUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub struct AFCloudServer {
  pub(crate) config: AFCloudConfiguration,
}

impl AFCloudServer {
  pub fn new(config: AFCloudConfiguration) -> Self {
    Self { config }
  }
}

impl AppFlowyServer for AFCloudServer {
  fn user_service(&self) -> Arc<dyn UserCloudService> {
    Arc::new(AFCloudUserAuthServiceImpl::new(self.config.clone()))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(AFCloudFolderCloudServiceImpl())
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(AFCloudDatabaseCloudServiceImpl())
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(AFCloudDocumentCloudServiceImpl())
  }

  fn collab_storage(&self, _collab_object: &CollabObject) -> Option<Arc<dyn RemoteCollabStorage>> {
    None
  }

  fn file_storage(&self) -> Option<Arc<dyn FileStorageService>> {
    None
  }
}
