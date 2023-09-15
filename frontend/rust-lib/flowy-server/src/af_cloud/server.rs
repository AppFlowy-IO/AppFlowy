use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use anyhow::Error;
use collab_define::CollabObject;
use collab_plugins::cloud_storage::RemoteCollabStorage;
use tokio::sync::RwLock;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_storage::FileStorageService;
use flowy_user_deps::cloud::UserCloudService;

use crate::af_cloud::configuration::AFCloudConfiguration;
use crate::af_cloud::impls::{
  AFCloudDatabaseCloudServiceImpl, AFCloudDocumentCloudServiceImpl, AFCloudFolderCloudServiceImpl,
  AFCloudUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub(crate) type AFCloudClient = RwLock<client_api::Client>;

pub struct AFCloudServer {
  pub(crate) config: AFCloudConfiguration,
  pub(crate) client: Arc<AFCloudClient>,
  enable_sync: AtomicBool,
  device_id: Arc<parking_lot::RwLock<String>>,
}

impl AFCloudServer {
  pub fn new(
    config: AFCloudConfiguration,
    enable_sync: bool,
    device_id: Arc<parking_lot::RwLock<String>>,
  ) -> Self {
    let http_client = reqwest::Client::new();
    let client = client_api::Client::from(http_client, &config.base_url(), &config.ws_addr());
    let enable_sync = AtomicBool::new(enable_sync);

    let client = Arc::new(RwLock::new(client));
    Self {
      config,
      client,
      enable_sync,
      device_id,
    }
  }

  fn get_client(&self) -> Option<Arc<AFCloudClient>> {
    if self.enable_sync.load(Ordering::SeqCst) {
      Some(self.client.clone())
    } else {
      None
    }
  }
}

impl AppFlowyServer for AFCloudServer {
  fn set_enable_sync(&self, uid: i64, enable: bool) {
    tracing::info!("{} cloud sync: {}", uid, enable);
    self.enable_sync.store(enable, Ordering::SeqCst);
  }
  fn user_service(&self) -> Arc<dyn UserCloudService> {
    let server = AFServerImpl(self.get_client());
    Arc::new(AFCloudUserAuthServiceImpl::new(server))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    let server = AFServerImpl(self.get_client());
    Arc::new(AFCloudFolderCloudServiceImpl(server))
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    let server = AFServerImpl(self.get_client());
    Arc::new(AFCloudDatabaseCloudServiceImpl(server))
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    let server = AFServerImpl(self.get_client());
    Arc::new(AFCloudDocumentCloudServiceImpl(server))
  }

  fn collab_storage(&self, _collab_object: &CollabObject) -> Option<Arc<dyn RemoteCollabStorage>> {
    None
  }

  fn file_storage(&self) -> Option<Arc<dyn FileStorageService>> {
    None
  }
}

pub trait AFServer: Send + Sync + 'static {
  fn get_client(&self) -> Option<Arc<AFCloudClient>>;
  fn try_get_client(&self) -> Result<Arc<AFCloudClient>, anyhow::Error>;
}

#[derive(Clone)]
pub struct AFServerImpl(pub Option<Arc<AFCloudClient>>);

impl AFServer for AFServerImpl {
  fn get_client(&self) -> Option<Arc<AFCloudClient>> {
    self.0.clone()
  }

  fn try_get_client(&self) -> Result<Arc<AFCloudClient>, Error> {
    match self.0.clone() {
      None => Err(
        FlowyError::new(
          ErrorCode::DataSyncRequired,
          "Data Sync is disabled, please enable it first",
        )
        .into(),
      ),
      Some(client) => Ok(client),
    }
  }
}
