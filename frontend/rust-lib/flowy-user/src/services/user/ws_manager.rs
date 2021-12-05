use crate::errors::UserError;
use lib_infra::entities::network_state::NetworkType;
use lib_ws::{WsConnectState, WsController};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::sync::broadcast;

pub struct WsManager {
    inner: Arc<WsController>,
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

    pub fn state_subscribe(&self) -> broadcast::Receiver<WsConnectState> { self.inner.state_subscribe() }

    #[tracing::instrument(level = "debug", skip(self))]
    fn listen_on_websocket(&self) {
        let mut notify = self.inner.state_subscribe();
        let ws_controller = self.inner.clone();
        let _ = tokio::spawn(async move {
            loop {
                match notify.recv().await {
                    Ok(state) => {
                        tracing::info!("Websocket state changed: {}", state);
                        match state {
                            WsConnectState::Init => {},
                            WsConnectState::Connected => {},
                            WsConnectState::Connecting => {},
                            WsConnectState::Disconnected => retry_connect(ws_controller.clone(), 100).await,
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
}

async fn retry_connect(ws_controller: Arc<WsController>, count: usize) {
    match ws_controller.retry(count).await {
        Ok(_) => {},
        Err(e) => {
            log::error!("websocket connect failed: {:?}", e);
        },
    }
}

impl std::default::Default for WsManager {
    fn default() -> Self {
        WsManager {
            inner: Arc::new(WsController::new()),
            connect_type: RwLock::new(NetworkType::default()),
        }
    }
}

impl std::ops::Deref for WsManager {
    type Target = WsController;

    fn deref(&self) -> &Self::Target { &self.inner }
}
