use std::str::FromStr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::Duration;

use crate::af_cloud::define::ServerUser;
use anyhow::Error;
use client_api::collab_sync::ServerCollabMessage;
use client_api::entity::ai_dto::AIModel;
use client_api::entity::UserMessage;
use client_api::notify::{TokenState, TokenStateReceiver};
use client_api::ws::{
  ConnectState, WSClient, WSClientConfig, WSConnectStateReceiver, WebSocketChannel,
};
use client_api::{Client, ClientConfiguration};

use flowy_chat_pub::cloud::ChatCloudService;
use flowy_database_pub::cloud::DatabaseCloudService;
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_error::{ErrorCode, FlowyError};
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_search_pub::cloud::SearchCloudService;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_storage_pub::cloud::StorageCloudService;
use flowy_user_pub::cloud::{UserCloudService, UserUpdate};
use flowy_user_pub::entities::UserTokenState;
use lib_dispatch::prelude::af_spawn;
use rand::Rng;
use semver::Version;
use tokio::select;
use tokio::sync::{watch, Mutex};
use tokio_stream::wrappers::WatchStream;
use tokio_util::sync::CancellationToken;
use tracing::{error, event, info, warn};
use uuid::Uuid;

use crate::af_cloud::impls::{
  AFCloudChatCloudServiceImpl, AFCloudDatabaseCloudServiceImpl, AFCloudDocumentCloudServiceImpl,
  AFCloudFileStorageServiceImpl, AFCloudFolderCloudServiceImpl, AFCloudUserAuthServiceImpl,
};

use crate::AppFlowyServer;

use super::impls::AFCloudSearchCloudServiceImpl;

pub(crate) type AFCloudClient = Client;

pub struct AppFlowyCloudServer {
  #[allow(dead_code)]
  pub(crate) config: AFCloudConfiguration,
  pub(crate) client: Arc<AFCloudClient>,
  enable_sync: Arc<AtomicBool>,
  network_reachable: Arc<AtomicBool>,
  pub device_id: String,
  ws_client: Arc<WSClient>,
  user: Arc<dyn ServerUser>,
}

impl AppFlowyCloudServer {
  pub fn new(
    config: AFCloudConfiguration,
    enable_sync: bool,
    mut device_id: String,
    client_version: Version,
    user: Arc<dyn ServerUser>,
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
      &client_version.to_string(),
    );
    let token_state_rx = api_client.subscribe_token_state();
    let enable_sync = Arc::new(AtomicBool::new(enable_sync));
    let network_reachable = Arc::new(AtomicBool::new(true));

    let ws_client = WSClient::new(
      WSClientConfig::default(),
      api_client.clone(),
      api_client.clone(),
    );
    let ws_client = Arc::new(ws_client);
    let api_client = Arc::new(api_client);
    let ws_connect_cancellation_token = Arc::new(Mutex::new(CancellationToken::new()));

    spawn_ws_conn(
      token_state_rx,
      &ws_client,
      ws_connect_cancellation_token,
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
      user,
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

  fn set_ai_model(&self, ai_model: &str) -> Result<(), Error> {
    self.client.set_ai_model(AIModel::from_str(ai_model)?);
    Ok(())
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

    Arc::new(AFCloudUserAuthServiceImpl::new(
      server,
      rx,
      self.user.clone(),
    ))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    Arc::new(AFCloudFolderCloudServiceImpl {
      inner: server,
      user: self.user.clone(),
    })
  }

  fn database_service(&self) -> Arc<dyn DatabaseCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    Arc::new(AFCloudDatabaseCloudServiceImpl {
      inner: server,
      user: self.user.clone(),
    })
  }

  fn document_service(&self) -> Arc<dyn DocumentCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    Arc::new(AFCloudDocumentCloudServiceImpl {
      inner: server,
      user: self.user.clone(),
    })
  }

  fn chat_service(&self) -> Arc<dyn ChatCloudService> {
    let server = AFServerImpl {
      client: self.get_client(),
    };
    Arc::new(AFCloudChatCloudServiceImpl { inner: server })
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
  ) -> Result<
    Option<(
      Arc<WebSocketChannel<ServerCollabMessage>>,
      WSConnectStateReceiver,
      bool,
    )>,
    Error,
  > {
    let object_id = _object_id.to_string();
    let channel = self.ws_client.subscribe_collab(object_id).ok();
    let connect_state_recv = self.ws_client.subscribe_connect_state();
    Ok(channel.map(|c| (c, connect_state_recv, self.ws_client.is_connected())))
  }

  fn file_storage(&self) -> Option<Arc<dyn StorageCloudService>> {
    let client = AFServerImpl {
      client: self.get_client(),
    };
    Some(Arc::new(AFCloudFileStorageServiceImpl::new(client)))
  }

  fn search_service(&self) -> Option<Arc<dyn SearchCloudService>> {
    let server = AFServerImpl {
      client: self.get_client(),
    };

    Some(Arc::new(AFCloudSearchCloudServiceImpl { inner: server }))
  }
}

/// Spawns a new asynchronous task to handle WebSocket connections based on token state.
///
/// This function listens to the `token_state_rx` channel for token state updates. Depending on the
/// received state, it either refreshes the WebSocket connection or disconnects from it.
fn spawn_ws_conn(
  mut token_state_rx: TokenStateReceiver,
  ws_client: &Arc<WSClient>,
  conn_cancellation_token: Arc<Mutex<CancellationToken>>,
  api_client: &Arc<Client>,
  enable_sync: &Arc<AtomicBool>,
) {
  let weak_ws_client = Arc::downgrade(ws_client);
  let weak_api_client = Arc::downgrade(api_client);
  let enable_sync = enable_sync.clone();
  let cloned_conn_cancellation_token = conn_cancellation_token.clone();

  af_spawn(async move {
    if let Some(ws_client) = weak_ws_client.upgrade() {
      let mut state_recv = ws_client.subscribe_connect_state();
      while let Ok(state) = state_recv.recv().await {
        info!("[websocket] state: {:?}", state);
        match state {
          ConnectState::PingTimeout | ConnectState::Lost => {
            // Try to reconnect if the connection is timed out.
            if weak_api_client.upgrade().is_some() && enable_sync.load(Ordering::SeqCst) {
              attempt_reconnect(&ws_client, 2, &cloned_conn_cancellation_token).await;
            }
          },
          ConnectState::Unauthorized => {
            if let Some(api_client) = weak_api_client.upgrade() {
              if let Err(err) = api_client
                .refresh_token("websocket connect unauthorized")
                .await
              {
                error!("Failed to refresh token: {}", err);
              }
            }
          },
          _ => {},
        }
      }
    }
  });

  let weak_ws_client = Arc::downgrade(ws_client);
  af_spawn(async move {
    while let Ok(token_state) = token_state_rx.recv().await {
      info!("🟢token state: {:?}", token_state);
      match token_state {
        TokenState::Refresh => {
          if let Some(ws_client) = weak_ws_client.upgrade() {
            attempt_reconnect(&ws_client, 5, &conn_cancellation_token).await;
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

/// Attempts to reconnect a WebSocket client with a randomized delay to mitigate the thundering herd problem.
///
/// This function cancels any existing reconnection attempt, sets up a new cancellation token, and then
/// attempts to reconnect after a randomized delay. The delay is set between a specified minimum and
/// that minimum plus 10 seconds.
///
async fn attempt_reconnect(
  ws_client: &Arc<WSClient>,
  minimum_delay_in_secs: u64,
  conn_cancellation_token: &Arc<Mutex<CancellationToken>>,
) {
  // Cancel the previous reconnection attempt
  let mut cancel_token_lock = conn_cancellation_token.lock().await;
  cancel_token_lock.cancel();

  let new_cancel_token = CancellationToken::new();
  *cancel_token_lock = new_cancel_token.clone();
  drop(cancel_token_lock);

  // randomness in the reconnection attempts to avoid thundering herd problem
  let delay_seconds = rand::thread_rng().gen_range(minimum_delay_in_secs..10);
  let ws_client = ws_client.clone();
  tokio::spawn(async move {
    select! {
      _ = new_cancel_token.cancelled() => {
        event!(
          tracing::Level::TRACE,
          "🟢websocket reconnection attempt cancelled."
        );
      },
      _ = tokio::time::sleep(Duration::from_secs(delay_seconds)) => {
        if let Err(e) = ws_client.connect().await {
          error!("Failed to reconnect websocket: {}", e);
        }
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
