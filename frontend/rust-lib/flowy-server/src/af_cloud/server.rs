use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use anyhow::Error;
use client_api::notify::{TokenState, TokenStateReceiver};
use client_api::ws::{BusinessID, WSClient, WSClientConfig, WebSocketChannel};
use client_api::Client;
use tokio::sync::RwLock;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_storage::FileStorageService;
use flowy_user_deps::cloud::UserCloudService;
use lib_infra::future::FutureResult;

use crate::af_cloud::configuration::AFCloudConfiguration;
use crate::af_cloud::impls::{
  AFCloudDatabaseCloudServiceImpl, AFCloudDocumentCloudServiceImpl, AFCloudFolderCloudServiceImpl,
  AFCloudUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub(crate) type AFCloudClient = RwLock<client_api::Client>;

pub struct AFCloudServer {
  #[allow(dead_code)]
  pub(crate) config: AFCloudConfiguration,
  pub(crate) client: Arc<AFCloudClient>,
  enable_sync: AtomicBool,
  #[allow(dead_code)]
  device_id: Arc<parking_lot::RwLock<String>>,
  ws_client: Arc<RwLock<WSClient>>,
}

impl AFCloudServer {
  pub fn new(
    config: AFCloudConfiguration,
    enable_sync: bool,
    device_id: Arc<parking_lot::RwLock<String>>,
  ) -> Self {
    let http_client = reqwest::Client::new();
    let api_client = client_api::Client::from(http_client, &config.base_url(), &config.ws_addr());
    let token_state_rx = api_client.subscribe_token_state();
    let enable_sync = AtomicBool::new(enable_sync);

    let ws_client = WSClient::new(WSClientConfig {
      buffer_capacity: 100,
      ping_per_secs: 2,
      retry_connect_per_pings: 5,
    });
    let ws_client = Arc::new(RwLock::new(ws_client));
    let api_client = Arc::new(RwLock::new(api_client));

    spawn_ws_conn(&device_id, token_state_rx, &ws_client, &api_client);
    Self {
      config,
      client: api_client,
      enable_sync,
      device_id,
      ws_client,
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

  fn collab_ws_channel(
    &self,
    object_id: &str,
  ) -> FutureResult<Option<Arc<WebSocketChannel>>, anyhow::Error> {
    if self.enable_sync.load(Ordering::SeqCst) {
      let object_id = object_id.to_string();
      let weak_ws_client = Arc::downgrade(&self.ws_client);
      FutureResult::new(async move {
        match weak_ws_client.upgrade() {
          None => {
            tracing::warn!("🟡Collab WS client is dropped");
            Ok(None)
          },
          Some(ws_client) => Ok(
            ws_client
              .read()
              .await
              .subscribe(BusinessID::CollabId, object_id)
              .await
              .ok(),
          ),
        }
      })
    } else {
      FutureResult::new(async { Ok(None) })
    }
  }

  fn file_storage(&self) -> Option<Arc<dyn FileStorageService>> {
    None
  }
}

/// Spawns a new asynchronous task to handle WebSocket connections based on token state.
///
/// This function listens to the `token_state_rx` channel for token state updates. Depending on the
/// received state, it either refreshes the WebSocket connection or disconnects from it.
fn spawn_ws_conn(
  device_id: &Arc<parking_lot::RwLock<String>>,
  mut token_state_rx: TokenStateReceiver,
  ws_client: &Arc<RwLock<WSClient>>,
  api_client: &Arc<RwLock<Client>>,
) {
  let weak_device_id = Arc::downgrade(device_id);
  let weak_ws_client = Arc::downgrade(ws_client);
  let weak_api_client = Arc::downgrade(api_client);
  tokio::spawn(async move {
    while let Ok(token_state) = token_state_rx.recv().await {
      tracing::info!("🟢Token state: {:?}", token_state);
      match token_state {
        TokenState::Refresh => {
          if let (Some(api_client), Some(ws_client), Some(device_id)) = (
            weak_api_client.upgrade(),
            weak_ws_client.upgrade(),
            weak_device_id.upgrade(),
          ) {
            let device_id = device_id.read().clone();
            if let Ok(ws_addr) = api_client.read().await.ws_url(&device_id) {
              tracing::info!("🟢Connecting to websocket");
              let _ = ws_client.write().await.connect(ws_addr).await;
            }
          }
        },
        TokenState::Invalid => {
          if let Some(ws_client) = weak_ws_client.upgrade() {
            tracing::info!("🟡Disconnecting from websocket");
            ws_client.write().await.disconnect().await;
          }
        },
      }
    }
  });
}

pub trait AFServer: Send + Sync + 'static {
  fn get_client(&self) -> Option<Arc<AFCloudClient>>;
  fn try_get_client(&self) -> Result<Arc<AFCloudClient>, Error>;
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
