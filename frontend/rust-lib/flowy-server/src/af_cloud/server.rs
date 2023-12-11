use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use anyhow::Error;
use client_api::collab_sync::collab_msg::CollabMessage;
use client_api::entity::UserMessage;
use client_api::notify::{TokenState, TokenStateReceiver};
use client_api::ws::{
  ConnectState, WSClient, WSClientConfig, WSConnectStateReceiver, WebSocketChannel,
};
use client_api::Client;
use tokio::sync::watch;
use tokio_stream::wrappers::WatchStream;
use tracing::{error, event, info};

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_storage::FileStorageService;
use flowy_user_deps::cloud::{UserCloudService, UserUpdate};
use flowy_user_deps::entities::UserTokenState;
use lib_dispatch::prelude::af_spawn;
use lib_infra::future::FutureResult;

use crate::af_cloud::impls::{
  AFCloudDatabaseCloudServiceImpl, AFCloudDocumentCloudServiceImpl, AFCloudFileStorageServiceImpl,
  AFCloudFolderCloudServiceImpl, AFCloudUserAuthServiceImpl,
};
use crate::AppFlowyServer;

pub(crate) type AFCloudClient = Client;

pub struct AppFlowyCloudServer {
  #[allow(dead_code)]
  pub(crate) config: AFCloudConfiguration,
  pub(crate) client: Arc<AFCloudClient>,
  enable_sync: Arc<AtomicBool>,
  network_reachable: Arc<AtomicBool>,
  #[allow(dead_code)]
  device_id: String,
  ws_client: Arc<WSClient>,
}

impl AppFlowyCloudServer {
  pub fn new(config: AFCloudConfiguration, enable_sync: bool, device_id: String) -> Self {
    let api_client = AFCloudClient::new(&config.base_url, &config.ws_base_url, &config.gotrue_url);
    let token_state_rx = api_client.subscribe_token_state();
    let enable_sync = Arc::new(AtomicBool::new(enable_sync));
    let network_reachable = Arc::new(AtomicBool::new(true));

    let ws_client = WSClient::new(WSClientConfig::default(), api_client.clone());
    let ws_client = Arc::new(ws_client);
    let api_client = Arc::new(api_client);

    spawn_ws_conn(
      &device_id,
      token_state_rx,
      &ws_client,
      &api_client,
      &enable_sync,
    );
    Self {
      config,
      client: api_client,
      enable_sync,
      network_reachable,
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

impl AppFlowyServer for AppFlowyCloudServer {
  fn set_token(&self, token: &str) -> Result<(), Error> {
    self
      .client
      .restore_token(token)
      .map_err(|err| Error::new(FlowyError::unauthorized().with_context(err)))
  }

  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    let mut token_state_rx = self.client.subscribe_token_state();
    let (watch_tx, watch_rx) = watch::channel(UserTokenState::Invalid);
    let weak_client = Arc::downgrade(&self.client);
    af_spawn(async move {
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

  fn set_network_reachable(&self, reachable: bool) {
    self.network_reachable.store(reachable, Ordering::SeqCst);
  }

  fn user_service(&self) -> Arc<dyn UserCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    let mut user_change = self.ws_client.subscribe_user_changed();
    let (tx, rx) = tokio::sync::mpsc::channel(1);
    tokio::spawn(async move {
      while let Ok(user_message) = user_change.recv().await {
        if let UserMessage::ProfileChange(change) = user_message {
          let user_update = UserUpdate {
            uid: change.uid,
            name: change.name,
            email: change.email,
            encryption_sign: "".to_string(),
          };
          let _ = tx.send(user_update).await;
        }
      }
    });

    Arc::new(AFCloudUserAuthServiceImpl::new(server, rx))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    Arc::new(AFCloudFolderCloudServiceImpl(server))
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    Arc::new(AFCloudDatabaseCloudServiceImpl(server))
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    Arc::new(AFCloudDocumentCloudServiceImpl(server))
  }

  #[allow(clippy::type_complexity)]
  fn collab_ws_channel(
    &self,
    _object_id: &str,
  ) -> FutureResult<
    Option<(
      Arc<WebSocketChannel<CollabMessage>>,
      WSConnectStateReceiver,
      bool,
    )>,
    Error,
  > {
    if self.enable_sync.load(Ordering::SeqCst) {
      let object_id = _object_id.to_string();
      let weak_ws_client = Arc::downgrade(&self.ws_client);
      FutureResult::new(async move {
        match weak_ws_client.upgrade() {
          None => Ok(None),
          Some(ws_client) => {
            let channel = ws_client.subscribe_collab(object_id).ok();
            let connect_state_recv = ws_client.subscribe_connect_state();
            Ok(channel.map(|c| (c, connect_state_recv, ws_client.is_connected())))
          },
        }
      })
    } else {
      FutureResult::new(async { Ok(None) })
    }
  }

  fn file_storage(&self) -> Option<Arc<dyn FileStorageService>> {
    let client = AFServerImpl {
      client: self.get_client(),
    };
    Some(Arc::new(AFCloudFileStorageServiceImpl::new(client)))
  }
}

/// Spawns a new asynchronous task to handle WebSocket connections based on token state.
///
/// This function listens to the `token_state_rx` channel for token state updates. Depending on the
/// received state, it either refreshes the WebSocket connection or disconnects from it.
fn spawn_ws_conn(
  device_id: &String,
  mut token_state_rx: TokenStateReceiver,
  ws_client: &Arc<WSClient>,
  api_client: &Arc<Client>,
  enable_sync: &Arc<AtomicBool>,
) {
  let cloned_device_id = device_id.to_owned();
  let weak_ws_client = Arc::downgrade(ws_client);
  let weak_api_client = Arc::downgrade(api_client);
  let enable_sync = enable_sync.clone();

  af_spawn(async move {
    if let Some(ws_client) = weak_ws_client.upgrade() {
      let mut state_recv = ws_client.subscribe_connect_state();
      while let Ok(state) = state_recv.recv().await {
        info!("[websocket] state: {:?}", state);
        match state {
          ConnectState::PingTimeout | ConnectState::Closed => {
            // Try to reconnect if the connection is timed out.
            if let Some(api_client) = weak_api_client.upgrade() {
              if enable_sync.load(Ordering::SeqCst) {
                match api_client.ws_url(&cloned_device_id) {
                  Ok(ws_addr) => {
                    event!(tracing::Level::INFO, "🟢reconnecting websocket");
                    let _ = ws_client.connect(ws_addr, &cloned_device_id).await;
                  },
                  Err(err) => error!("Failed to get ws url: {}", err),
                }
              }
            }
          },
          ConnectState::Unauthorized => {
            if let Some(api_client) = weak_api_client.upgrade() {
              if let Err(err) = api_client.refresh_token().await {
                error!("Failed to refresh token: {}", err);
              }
            }
          },
          _ => {},
        }
      }
    }
  });

  let device_id = device_id.to_owned();
  let weak_ws_client = Arc::downgrade(ws_client);
  let weak_api_client = Arc::downgrade(api_client);
  af_spawn(async move {
    while let Ok(token_state) = token_state_rx.recv().await {
      match token_state {
        TokenState::Refresh => {
          if let (Some(api_client), Some(ws_client)) =
            (weak_api_client.upgrade(), weak_ws_client.upgrade())
          {
            match api_client.ws_url(&device_id) {
              Ok(ws_addr) => {
                info!("🟢token state: {:?}, reconnecting websocket", token_state);
                let _ = ws_client.connect(ws_addr, &device_id).await;
              },
              Err(err) => error!("Failed to get ws url: {}", err),
            }
          }
        },
        TokenState::Invalid => {
          if let Some(ws_client) = weak_ws_client.upgrade() {
            info!("🟢token state: {:?}, disconnect websocket", token_state);
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
pub struct AFServerImpl {
  client: Option<Arc<AFCloudClient>>,
}

impl AFServer for AFServerImpl {
  fn get_client(&self) -> Option<Arc<AFCloudClient>> {
    self.client.clone()
  }

  fn try_get_client(&self) -> Result<Arc<AFCloudClient>, Error> {
    match self.client.clone() {
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
