use futures_util::future::BoxFuture;
use lib_infra::future::FutureResult;
use lib_ws::WSController;
pub use lib_ws::{WSConnectState, WSMessageReceiver, WebSocketRawMessage};
use parking_lot::RwLock;
use serde_repr::*;
use std::sync::Arc;
use thiserror::Error;
use tokio::sync::broadcast;

#[derive(Debug, Clone, PartialEq, Eq, Error, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum WSErrorCode {
  #[error("Internal error")]
  Internal = 0,
}

pub trait FlowyRawWebSocket: Send + Sync {
  fn initialize(&self) -> FutureResult<(), WSErrorCode>;
  fn start_connect(&self, addr: String, user_id: String) -> FutureResult<(), WSErrorCode>;
  fn stop_connect(&self) -> FutureResult<(), WSErrorCode>;
  fn subscribe_connect_state(&self) -> BoxFuture<broadcast::Receiver<WSConnectState>>;
  fn reconnect(&self, count: usize) -> FutureResult<(), WSErrorCode>;
  fn add_msg_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), WSErrorCode>;
  fn ws_msg_sender(&self) -> FutureResult<Option<Arc<dyn FlowyWebSocket>>, WSErrorCode>;
}

pub trait FlowyWebSocket: Send + Sync {
  fn send(&self, msg: WebSocketRawMessage) -> Result<(), WSErrorCode>;
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum NetworkType {
  Unknown = 0,
  Wifi = 1,
  Cell = 2,
  Ethernet = 3,
  Bluetooth = 4,
  VPN = 5,
}

impl std::default::Default for NetworkType {
  fn default() -> Self {
    NetworkType::Unknown
  }
}

impl NetworkType {
  pub fn is_connect(&self) -> bool {
    !matches!(self, NetworkType::Unknown | NetworkType::Bluetooth)
  }
}

pub struct FlowyWebSocketConnect {
  inner: Arc<dyn FlowyRawWebSocket>,
  connect_type: RwLock<NetworkType>,
  status_notifier: broadcast::Sender<NetworkType>,
  addr: String,
}

impl FlowyWebSocketConnect {
  pub fn new(addr: String) -> Self {
    let ws = Arc::new(Arc::new(WSController::new()));
    let (status_notifier, _) = broadcast::channel(10);
    FlowyWebSocketConnect {
      inner: ws,
      connect_type: RwLock::new(NetworkType::default()),
      status_notifier,
      addr,
    }
  }

  pub fn from_local(addr: String, ws: Arc<dyn FlowyRawWebSocket>) -> Self {
    let (status_notifier, _) = broadcast::channel(10);
    FlowyWebSocketConnect {
      inner: ws,
      connect_type: RwLock::new(NetworkType::default()),
      status_notifier,
      addr,
    }
  }

  pub async fn init(&self) {
    match self.inner.initialize().await {
      Ok(_) => {},
      Err(e) => tracing::error!("FlowyWebSocketConnect init error: {:?}", e),
    }
  }

  pub async fn start(&self, token: String, user_id: String) -> Result<(), WSErrorCode> {
    let addr = format!("{}/{}", self.addr, &token);
    self.inner.stop_connect().await?;
    self.inner.start_connect(addr, user_id).await?;
    Ok(())
  }

  pub async fn stop(&self) {
    let _ = self.inner.stop_connect().await;
  }

  pub fn update_network_type(&self, new_type: NetworkType) {
    tracing::debug!("Network new state: {:?}", new_type);
    let old_type = self.connect_type.read().clone();
    let _ = self.status_notifier.send(new_type.clone());

    if old_type != new_type {
      tracing::debug!("Connect type switch from {:?} to {:?}", old_type, new_type);
      match (old_type.is_connect(), new_type.is_connect()) {
        (false, true) => {
          let ws_controller = self.inner.clone();
          tokio::spawn(async move { retry_connect(ws_controller, 100).await });
        },
        (true, false) => {
          //
        },
        _ => {},
      }

      *self.connect_type.write() = new_type;
    }
  }

  pub async fn subscribe_websocket_state(&self) -> broadcast::Receiver<WSConnectState> {
    self.inner.subscribe_connect_state().await
  }

  pub fn subscribe_network_ty(&self) -> broadcast::Receiver<NetworkType> {
    self.status_notifier.subscribe()
  }

  pub fn add_ws_message_receiver(
    &self,
    receiver: Arc<dyn WSMessageReceiver>,
  ) -> Result<(), WSErrorCode> {
    self.inner.add_msg_receiver(receiver)?;
    Ok(())
  }

  pub async fn web_socket(&self) -> Result<Option<Arc<dyn FlowyWebSocket>>, WSErrorCode> {
    self.inner.ws_msg_sender().await
  }
}

#[tracing::instrument(level = "debug", skip(ws_conn))]
pub fn listen_on_websocket(ws_conn: Arc<FlowyWebSocketConnect>) {
  let raw_web_socket = ws_conn.inner.clone();
  let _ = tokio::spawn(async move {
    let mut notify = ws_conn.inner.subscribe_connect_state().await;
    loop {
      match notify.recv().await {
        Ok(state) => {
          tracing::info!("Websocket state changed: {}", state);
          match state {
            WSConnectState::Init => {},
            WSConnectState::Connected => {},
            WSConnectState::Connecting => {},
            WSConnectState::Disconnected => retry_connect(raw_web_socket.clone(), 100).await,
          }
        },
        Err(e) => {
          tracing::error!("Websocket state notify error: {:?}", e);
          break;
        },
      }
    }
  });
}

async fn retry_connect(ws: Arc<dyn FlowyRawWebSocket>, count: usize) {
  match ws.reconnect(count).await {
    Ok(_) => {},
    Err(e) => {
      tracing::error!("websocket connect failed: {:?}", e);
    },
  }
}
