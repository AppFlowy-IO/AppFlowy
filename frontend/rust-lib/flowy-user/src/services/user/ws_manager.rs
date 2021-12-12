use crate::errors::UserError;

use lib_infra::{entities::network_state::NetworkType, future::ResultFuture};
use lib_ws::{WsConnectState, WsController, WsMessage, WsMessageHandler, WsSender};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver};

pub trait FlowyWebSocket: Send + Sync {
    fn start_connect(&self, addr: String) -> ResultFuture<(), UserError>;
    fn conn_state_subscribe(&self) -> broadcast::Receiver<WsConnectState>;
    fn reconnect(&self, count: usize) -> ResultFuture<(), UserError>;
    fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), UserError>;
    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, UserError>;
}

pub trait FlowyWsSender: Send + Sync {
    fn send(&self, msg: WsMessage) -> Result<(), UserError>;
}

pub struct WsManager {
    inner: Arc<dyn FlowyWebSocket>,
    connect_type: RwLock<NetworkType>,
}

impl WsManager {
    pub fn new() -> Self { WsManager::default() }

    pub async fn start(&self, addr: String) -> Result<(), UserError> {
        self.listen_on_websocket();
        let _ = self.inner.start_connect(addr).await?;
        Ok(())
    }

    pub fn update_network_type(&self, new_type: &NetworkType) {
        let old_type = self.connect_type.read().clone();
        if &old_type != new_type {
            log::debug!("Connect type switch from {:?} to {:?}", old_type, new_type);
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

    #[tracing::instrument(level = "debug", skip(self))]
    fn listen_on_websocket(&self) {
        let mut notify = self.inner.conn_state_subscribe();
        let ws = self.inner.clone();
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
                        log::error!("Websocket state notify error: {:?}", e);
                        break;
                    },
                }
            }
        });
    }

    pub fn state_subscribe(&self) -> broadcast::Receiver<WsConnectState> { self.inner.conn_state_subscribe() }

    pub fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), UserError> {
        let _ = self.inner.add_handler(handler)?;
        Ok(())
    }

    pub fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, UserError> {
        //
        self.inner.ws_sender()
    }
}

async fn retry_connect(ws: Arc<dyn FlowyWebSocket>, count: usize) {
    match ws.reconnect(count).await {
        Ok(_) => {},
        Err(e) => {
            log::error!("websocket connect failed: {:?}", e);
        },
    }
}

impl std::default::Default for WsManager {
    fn default() -> Self {
        let ws: Arc<dyn FlowyWebSocket> = if cfg!(feature = "http_server") {
            Arc::new(Arc::new(WsController::new()))
        } else {
            crate::services::server::local_web_socket()
        };

        WsManager {
            inner: ws,
            connect_type: RwLock::new(NetworkType::default()),
        }
    }
}

impl FlowyWebSocket for Arc<WsController> {
    fn start_connect(&self, addr: String) -> ResultFuture<(), UserError> {
        let cloned_ws = self.clone();
        ResultFuture::new(async move {
            let _ = cloned_ws.start(addr).await?;
            Ok(())
        })
    }

    fn conn_state_subscribe(&self) -> Receiver<WsConnectState> { self.state_subscribe() }

    fn reconnect(&self, count: usize) -> ResultFuture<(), UserError> {
        let cloned_ws = self.clone();
        ResultFuture::new(async move {
            let _ = cloned_ws.retry(count).await?;
            Ok(())
        })
    }

    fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), UserError> {
        let _ = self.add_handler(handler)?;
        Ok(())
    }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, UserError> {
        let sender = self.sender()?;
        Ok(sender)
    }
}

impl FlowyWsSender for WsSender {
    fn send(&self, msg: WsMessage) -> Result<(), UserError> {
        let _ = self.send_msg(msg)?;
        Ok(())
    }
}
