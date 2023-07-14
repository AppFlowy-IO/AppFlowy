use std::sync::Arc;

use appflowy_integrate::RemoteCollabStorage;

use flowy_database2::deps::DatabaseCloudService;
use flowy_document2::deps::DocumentCloudService;
use flowy_folder2::deps::FolderCloudService;
use flowy_user::event_map::UserAuthService;

use crate::self_host::configuration::SelfHostedConfiguration;
use crate::self_host::impls::{
  SelfHostedDatabaseCloudServiceImpl, SelfHostedDocumentCloudServiceImpl,
  SelfHostedServerFolderCloudServiceImpl, SelfHostedUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub struct SelfHostServer {
  pub(crate) config: SelfHostedConfiguration,
}

impl SelfHostServer {
  pub fn new(config: SelfHostedConfiguration) -> Self {
    Self { config }
  }
}

impl AppFlowyServer for SelfHostServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(SelfHostedUserAuthServiceImpl::new(self.config.clone()))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    Arc::new(SelfHostedServerFolderCloudServiceImpl())
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    Arc::new(SelfHostedDatabaseCloudServiceImpl())
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    Arc::new(SelfHostedDocumentCloudServiceImpl())
  }

  fn collab_storage(&self) -> Option<Arc<dyn RemoteCollabStorage>> {
    None
  }
}
