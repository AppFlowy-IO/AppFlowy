use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use anyhow::Error;
use client_api::notify::{TokenState, TokenStateReceiver};
use client_api::ws::{
  BusinessID, WSClient, WSClientConfig, WSConnectStateReceiver, WebSocketChannel,
};
use client_api::Client;
use tokio::sync::watch;
use tokio_stream::wrappers::WatchStream;
use tracing::{error, info};

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_storage::FileStorageService;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::UserTokenState;
use lib_infra::future::FutureResult;

use crate::af_cloud::impls::{
  AFCloudDatabaseCloudServiceImpl, AFCloudDocumentCloudServiceImpl, AFCloudFileStorageServiceImpl,
  AFCloudFolderCloudServiceImpl, AFCloudUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub(crate) type AFCloudClient = client_api::Client;

pub struct AFCloudServer {
  #[allow(dead_code)]
  pub(crate) config: AFCloudConfiguration,
  pub(crate) client: Arc<AFCloudClient>,
  enable_sync: AtomicBool,
  #[allow(dead_code)]
  device_id: Arc<parking_lot::RwLock<String>>,
  ws_client: Arc<WSClient>,
}

impl AFCloudServer {
  pub fn new(
    config: AFCloudConfiguration,
    enable_sync: bool,
    device_id: Arc<parking_lot::RwLock<String>>,
  ) -> Self {
    let api_client = AFCloudClient::new(&config.base_url, &config.ws_base_url, &config.gotrue_url);
    let token_state_rx = api_client.subscribe_token_state();
    let enable_sync = AtomicBool::new(enable_sync);

    let ws_client = WSClient::new(WSClientConfig {
      buffer_capacity: 100,
      ping_per_secs: 8,
      retry_connect_per_pings: 6,
    });
    let ws_client = Arc::new(ws_client);
    let api_client = Arc::new(api_client);

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
  fn set_token(&self, token: &str) -> Result<(), Error> {
    self
      .client
      .set_token(token)
      .map_err(|err| Error::new(FlowyError::unauthorized().with_context(err)))
  }

  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    let mut token_state_rx = self.client.subscribe_token_state();
    let (watch_tx, watch_rx) = watch::channel(UserTokenState::Invalid);
    let weak_client = Arc::downgrade(&self.client);
    tokio::spawn(async move {
      while let Ok(token_state) = token_state_rx.recv().await {
        if let Some(client) = weak_client.upgrade() {
          match token_state {
            TokenState::Refresh => match client.get_token() {
              Ok(token) => {
                let _ = watch_tx.send(UserTokenState::Refresh { token });
              },
              Err(err) => {
                error!("Failed to get token after token state changed: {}", err);
              },
            },
            TokenState::Invalid => {
              let _ = watch_tx.send(UserTokenState::Invalid);
            },
          }
        }
      }
    });

    Some(WatchStream::new(watch_rx))
  }

  fn set_enable_sync(&self, uid: i64, enable: bool) {
    info!("{} cloud sync: {}", uid, enable);
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
  ) -> FutureResult<Option<(Arc<WebSocketChannel>, WSConnectStateReceiver)>, anyhow::Error> {
    if self.enable_sync.load(Ordering::SeqCst) {
      let object_id = object_id.to_string();
      let weak_ws_client = Arc::downgrade(&self.ws_client);
      FutureResult::new(async move {
        match weak_ws_client.upgrade() {
          None => Ok(None),
          Some(ws_client) => {
            let channel = ws_client.subscribe(BusinessID::CollabId, object_id).ok();
            let connect_state_recv = ws_client.subscribe_connect_state();
            Ok(channel.map(|c| (c, connect_state_recv)))
          },
        }
      })
    } else {
      FutureResult::new(async { Ok(None) })
    }
  }

  fn file_storage(&self) -> Option<Arc<dyn FileStorageService>> {
    let client = AFServerImpl(self.get_client());
    Some(Arc::new(AFCloudFileStorageServiceImpl::new(client)))
  }
}

/// Spawns a new asynchronous task to handle WebSocket connections based on token state.
///
/// This function listens to the `token_state_rx` channel for token state updates. Depending on the
/// received state, it either refreshes the WebSocket connection or disconnects from it.
fn spawn_ws_conn(
  device_id: &Arc<parking_lot::RwLock<String>>,
  mut token_state_rx: TokenStateReceiver,
  ws_client: &Arc<WSClient>,
  api_client: &Arc<Client>,
) {
  let weak_device_id = Arc::downgrade(device_id);
  let weak_ws_client = Arc::downgrade(ws_client);
  let weak_api_client = Arc::downgrade(api_client);

  tokio::spawn(async move {
    if let Some(ws_client) = weak_ws_client.upgrade() {
      let mut state_recv = ws_client.subscribe_connect_state();
      while let Ok(state) = state_recv.recv().await {
        if !state.is_timeout() {
          continue;
        }

        // Try to reconnect if the connection is timed out.
        if let (Some(api_client), Some(device_id)) =
          (weak_api_client.upgrade(), weak_device_id.upgrade())
        {
          let device_id = device_id.read().clone();
          if let Ok(ws_addr) = api_client.ws_url(&device_id) {
            info!("🟢WebSocket Reconnecting");
            let _ = ws_client.connect(ws_addr).await;
          }
        }
      }
    }
  });

  let weak_device_id = Arc::downgrade(device_id);
  let weak_ws_client = Arc::downgrade(ws_client);
  let weak_api_client = Arc::downgrade(api_client);
  tokio::spawn(async move {
    while let Ok(token_state) = token_state_rx.recv().await {
      info!("🟢Token state: {:?}", token_state);
      match token_state {
        TokenState::Refresh => {
          if let (Some(api_client), Some(ws_client), Some(device_id)) = (
            weak_api_client.upgrade(),
            weak_ws_client.upgrade(),
            weak_device_id.upgrade(),
          ) {
            let device_id = device_id.read().clone();
            if let Ok(ws_addr) = api_client.ws_url(&device_id) {
              let _ = ws_client.connect(ws_addr).await;
            }
          }
        },
        TokenState::Invalid => {
          if let Some(ws_client) = weak_ws_client.upgrade() {
            info!("🟡WebSocket Disconnecting");
            ws_client.disconnect().await;
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
