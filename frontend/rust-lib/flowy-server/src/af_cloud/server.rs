use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use anyhow::Error;
use client_api::collab_sync::collab_msg::ServerCollabMessage;
use client_api::entity::UserMessage;
use client_api::notify::{TokenState, TokenStateReceiver};
use client_api::ws::{
  ConnectState, WSClient, WSClientConfig, WSConnectStateReceiver, WebSocketChannel,
};
use client_api::{Client, ClientConfiguration};
use flowy_storage::ObjectStorageService;
use tokio::sync::watch;
use tokio_stream::wrappers::WatchStream;
use tracing::{error, event, info, warn};
use uuid::Uuid;

use flowy_database_pub::cloud::DatabaseCloudService;
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_user_pub::cloud::{UserCloudService, UserUpdate};
use flowy_user_pub::entities::UserTokenState;
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
  pub device_id: String,
  ws_client: Arc<WSClient>,
}

impl AppFlowyCloudServer {
  pub fn new(
    config: AFCloudConfiguration,
    enable_sync: bool,
    mut device_id: String,
    app_version: &str,
  ) -> Self {
    // The device id can't be empty, so we generate a new one if it is.
    if device_id.is_empty() {
      warn!("Device ID is empty, generating a new one");
      device_id = Uuid::new_v4().to_string();
    }

    let api_client = AFCloudClient::new(
      &config.base_url,
      &config.ws_base_url,
      &config.gotrue_url,
      &device_id,
      ClientConfiguration::default()
        .with_compression_buffer_size(10240)
        .with_compression_quality(8),
      app_version,
    );
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
    let (watch_tx, watch_rx) = watch::channel(UserTokenState::Init);
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
    af_spawn(async move {
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

  fn subscribe_ws_state(&self) -> Option<WSConnectStateReceiver> {
    Some(self.ws_client.subscribe_connect_state())
  }

  fn get_ws_state(&self) -> ConnectState {
    self.ws_client.get_state()
  }

  #[allow(clippy::type_complexity)]
  fn collab_ws_channel(
    &self,
    _object_id: &str,
  ) -> FutureResult<
    Option<(
      Arc<WebSocketChannel<ServerCollabMessage>>,
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

  fn file_storage(&self) -> Option<Arc<dyn ObjectStorageService>> {
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
                match api_client.ws_url(&cloned_device_id).await {
                  Ok(ws_addr) => {
                    // sleep two seconds and then try to reconnect
                    tokio::time::sleep(Duration::from_secs(2)).await;

                    event!(tracing::Level::INFO, "🟢reconnecting websocket");
                    let _ = ws_client.connect(ws_addr, &cloned_device_id).await;
                  },
                  Err(err) => error!("Failed to get ws url: {}, connect state:{:?}", err, state),
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
      info!("🟢token state: {:?}", token_state);
      match token_state {
        TokenState::Refresh => {
          if let (Some(api_client), Some(ws_client)) =
            (weak_api_client.upgrade(), weak_ws_client.upgrade())
          {
            match api_client.ws_url(&device_id).await {
              Ok(ws_addr) => {
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
