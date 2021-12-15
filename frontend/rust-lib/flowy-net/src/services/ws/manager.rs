use crate::{
    entities::NetworkType,
    services::ws::{local_web_socket, FlowyWebSocket, FlowyWsSender},
};
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;
use lib_ws::{WsConnectState, WsController, WsMessage, WsMessageHandler, WsSender};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver};

pub struct WsManager {
    inner: Arc<dyn FlowyWebSocket>,
    connect_type: RwLock<NetworkType>,
    status_notifier: broadcast::Sender<NetworkType>,
    addr: String,
}

impl WsManager {
    pub fn new(addr: String) -> Self {
        let ws: Arc<dyn FlowyWebSocket> = if cfg!(feature = "http_server") {
            Arc::new(Arc::new(WsController::new()))
        } else {
            local_web_socket()
        };
        let (status_notifier, _) = broadcast::channel(10);
        listen_on_websocket(ws.clone());
        WsManager {
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

    pub fn subscribe_websocket_state(&self) -> broadcast::Receiver<WsConnectState> {
        self.inner.subscribe_connect_state()
    }

    pub fn subscribe_network_ty(&self) -> broadcast::Receiver<NetworkType> { self.status_notifier.subscribe() }

    pub fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), FlowyError> {
        let _ = self.inner.add_ws_message_handler(handler)?;
        Ok(())
    }

    pub fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, FlowyError> { self.inner.ws_sender() }
}

#[tracing::instrument(level = "debug", skip(ws))]
fn listen_on_websocket(ws: Arc<dyn FlowyWebSocket>) {
    let mut notify = ws.subscribe_connect_state();
    let _ = tokio::spawn(async move {
        loop {
            match notify.recv().await {
                Ok(state) => {
                    tracing::info!("Websocket state changed: {}", state);
                    match state {
                        WsConnectState::Init => {},
                        WsConnectState::Connected => {},
                        WsConnectState::Connecting => {},
                        WsConnectState::Disconnected => retry_connect(ws.clone(), 100).await,
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

async fn retry_connect(ws: Arc<dyn FlowyWebSocket>, count: usize) {
    match ws.reconnect(count).await {
        Ok(_) => {},
        Err(e) => {
            tracing::error!("websocket connect failed: {:?}", e);
        },
    }
}

impl FlowyWebSocket for Arc<WsController> {
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

    fn subscribe_connect_state(&self) -> Receiver<WsConnectState> { self.subscribe_state() }

    fn reconnect(&self, count: usize) -> FutureResult<(), FlowyError> {
        let cloned_ws = self.clone();
        FutureResult::new(async move {
            let _ = cloned_ws.retry(count).await.map_err(internal_error)?;
            Ok(())
        })
    }

    fn add_ws_message_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), FlowyError> {
        let _ = self.add_handler(handler).map_err(internal_error)?;
        Ok(())
    }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, FlowyError> {
        let sender = self.sender().map_err(internal_error)?;
        Ok(sender)
    }
}

impl FlowyWsSender for WsSender {
    fn send(&self, msg: WsMessage) -> Result<(), FlowyError> {
        let _ = self.send_msg(msg).map_err(internal_error)?;
        Ok(())
    }
}
