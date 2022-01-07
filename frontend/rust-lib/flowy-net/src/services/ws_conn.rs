use crate::entities::NetworkType;

pub use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
pub use lib_ws::{WSConnectState, WSMessageReceiver, WebSocketRawMessage};

use parking_lot::RwLock;
use std::sync::Arc;
use tokio::sync::broadcast;

pub trait FlowyRawWebSocket: Send + Sync {
    fn start_connect(&self, addr: String) -> FutureResult<(), FlowyError>;
    fn stop_connect(&self) -> FutureResult<(), FlowyError>;
    fn subscribe_connect_state(&self) -> broadcast::Receiver<WSConnectState>;
    fn reconnect(&self, count: usize) -> FutureResult<(), FlowyError>;
    fn add_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError>;
    fn sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError>;
}

pub trait FlowyWSSender: Send + Sync {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError>;
}

pub struct FlowyWebSocketConnect {
    inner: Arc<dyn FlowyRawWebSocket>,
    connect_type: RwLock<NetworkType>,
    status_notifier: broadcast::Sender<NetworkType>,
    addr: String,
}

impl FlowyWebSocketConnect {
    pub fn new(addr: String, ws: Arc<dyn FlowyRawWebSocket>) -> Self {
        let (status_notifier, _) = broadcast::channel(10);
        FlowyWebSocketConnect {
            inner: ws,
            connect_type: RwLock::new(NetworkType::default()),
            status_notifier,
            addr,
        }
    }

    pub async fn start(&self, token: String) -> Result<(), FlowyError> {
        let addr = format!("{}/{}", self.addr, token);
        self.inner.stop_connect().await?;
        let _ = self.inner.start_connect(addr).await?;
        Ok(())
    }

    pub async fn stop(&self) { let _ = self.inner.stop_connect().await; }

    pub fn update_network_type(&self, new_type: &NetworkType) {
        tracing::debug!("Network new state: {:?}", new_type);
        let old_type = self.connect_type.read().clone();
        let _ = self.status_notifier.send(new_type.clone());

        if &old_type != new_type {
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

            *self.connect_type.write() = new_type.clone();
        }
    }

    pub fn subscribe_websocket_state(&self) -> broadcast::Receiver<WSConnectState> {
        self.inner.subscribe_connect_state()
    }

    pub fn subscribe_network_ty(&self) -> broadcast::Receiver<NetworkType> { self.status_notifier.subscribe() }

    pub fn add_ws_message_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        let _ = self.inner.add_receiver(receiver)?;
        Ok(())
    }

    pub fn ws_sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> { self.inner.sender() }
}

#[tracing::instrument(level = "debug", skip(ws_conn))]
pub fn listen_on_websocket(ws_conn: Arc<FlowyWebSocketConnect>) {
    if cfg!(feature = "http_server") {
        let ws = ws_conn.inner.clone();
        let mut notify = ws_conn.inner.subscribe_connect_state();
        let _ = tokio::spawn(async move {
            loop {
                match notify.recv().await {
                    Ok(state) => {
                        tracing::info!("Websocket state changed: {}", state);
                        match state {
                            WSConnectState::Init => {},
                            WSConnectState::Connected => {},
                            WSConnectState::Connecting => {},
                            WSConnectState::Disconnected => retry_connect(ws.clone(), 100).await,
                        }
                    },
                    Err(e) => {
                        tracing::error!("Websocket state notify error: {:?}", e);
                        break;
                    },
                }
            }
        });
    } else {
        // do nothing
    };
}

async fn retry_connect(ws: Arc<dyn FlowyRawWebSocket>, count: usize) {
    match ws.reconnect(count).await {
        Ok(_) => {},
        Err(e) => {
            tracing::error!("websocket connect failed: {:?}", e);
        },
    }
}
