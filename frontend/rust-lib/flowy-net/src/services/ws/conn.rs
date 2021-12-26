use crate::entities::NetworkType;
use flowy_error::internal_error;
pub use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
pub use lib_ws::{WSConnectState, WSMessageReceiver, WebSocketRawMessage};
use lib_ws::{WSController, WSSender};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver};

pub trait FlowyWebSocket: Send + Sync {
    fn start_connect(&self, addr: String) -> FutureResult<(), FlowyError>;
    fn stop_connect(&self) -> FutureResult<(), FlowyError>;
    fn subscribe_connect_state(&self) -> broadcast::Receiver<WSConnectState>;
    fn reconnect(&self, count: usize) -> FutureResult<(), FlowyError>;
    fn add_message_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError>;
    fn ws_sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError>;
}

pub trait FlowyWSSender: Send + Sync {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError>;
}

pub struct FlowyWSConnect {
    inner: Arc<dyn FlowyWebSocket>,
    connect_type: RwLock<NetworkType>,
    status_notifier: broadcast::Sender<NetworkType>,
    addr: String,
}

impl FlowyWSConnect {
    pub fn new(addr: String, ws: Arc<dyn FlowyWebSocket>) -> Self {
        let (status_notifier, _) = broadcast::channel(10);
        FlowyWSConnect {
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

    pub fn add_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        let _ = self.inner.add_message_receiver(handler)?;
        Ok(())
    }

    pub fn ws_sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> { self.inner.ws_sender() }
}

#[tracing::instrument(level = "debug", skip(manager))]
pub fn listen_on_websocket(manager: Arc<FlowyWSConnect>) {
    if cfg!(feature = "http_server") {
        let ws = manager.inner.clone();
        let mut notify = manager.inner.subscribe_connect_state();
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

async fn retry_connect(ws: Arc<dyn FlowyWebSocket>, count: usize) {
    match ws.reconnect(count).await {
        Ok(_) => {},
        Err(e) => {
            tracing::error!("websocket connect failed: {:?}", e);
        },
    }
}

impl FlowyWebSocket for Arc<WSController> {
    fn start_connect(&self, addr: String) -> FutureResult<(), FlowyError> {
        let cloned_ws = self.clone();
        FutureResult::new(async move {
            let _ = cloned_ws.start(addr).await.map_err(internal_error)?;
            Ok(())
        })
    }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> {
        let controller = self.clone();
        FutureResult::new(async move {
            controller.stop().await;
            Ok(())
        })
    }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.subscribe_state() }

    fn reconnect(&self, count: usize) -> FutureResult<(), FlowyError> {
        let cloned_ws = self.clone();
        FutureResult::new(async move {
            let _ = cloned_ws.retry(count).await.map_err(internal_error)?;
            Ok(())
        })
    }

    fn add_message_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        let _ = self.add_receiver(handler).map_err(internal_error)?;
        Ok(())
    }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> {
        let sender = self.sender().map_err(internal_error)?;
        Ok(sender)
    }
}

impl FlowyWSSender for WSSender {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError> {
        let _ = self.send_msg(msg).map_err(internal_error)?;
        Ok(())
    }
}
