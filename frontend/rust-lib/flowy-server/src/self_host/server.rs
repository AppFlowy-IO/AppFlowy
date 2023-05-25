use flowy_folder2::deps::FolderCloudService;
use std::sync::Arc;

use flowy_user::event_map::UserAuthService;

use crate::self_host::configuration::SelfHostedConfiguration;
use crate::self_host::impls::{
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
}
