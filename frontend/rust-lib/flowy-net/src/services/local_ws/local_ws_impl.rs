use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::*;
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;
use lib_ws::{WSConnectState, WSMessageReceiver, WSModule, WebSocketRawMessage};

use crate::services::{
    local_ws::local_server::LocalDocumentServer,
    ws_conn::{FlowyRawWebSocket, FlowyWSSender},
};
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{broadcast, broadcast::Receiver, mpsc, mpsc::UnboundedReceiver};

pub struct LocalWebSocket {
    receivers: Arc<DashMap<WSModule, Arc<dyn WSMessageReceiver>>>,
    state_sender: broadcast::Sender<WSConnectState>,
    ws_sender: LocalWSSender,
    server: Arc<LocalDocumentServer>,
    server_rx: RwLock<Option<UnboundedReceiver<WebSocketRawMessage>>>,
    user_id: Arc<RwLock<Option<String>>>,
}

impl std::default::Default for LocalWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let ws_sender = LocalWSSender::default();
        let receivers = Arc::new(DashMap::new());

        let (server_tx, server_rx) = mpsc::unbounded_channel();
        let server = Arc::new(LocalDocumentServer::new(server_tx));
        let server_rx = RwLock::new(Some(server_rx));
        let user_token = Arc::new(RwLock::new(None));

        LocalWebSocket {
            receivers,
            state_sender,
            ws_sender,
            server,
            server_rx,
            user_id: user_token,
        }
    }
}

impl LocalWebSocket {
    fn spawn_client(&self, _addr: String) {
        let mut ws_receiver = self.ws_sender.subscribe();
        let local_server = self.server.clone();
        let user_id = self.user_id.clone();
        tokio::spawn(async move {
            loop {
                // Polling the web socket message sent by user
                match ws_receiver.recv().await {
                    Ok(message) => {
                        let user_id = user_id.read().clone();
                        if user_id.is_none() {
                            continue;
                        }
                        let user_id = user_id.unwrap();
                        let server = local_server.clone();
                        let fut = || async move {
                            let bytes = Bytes::from(message.data);
                            let client_data = DocumentClientWSData::try_from(bytes).map_err(internal_error)?;
                            let _ = server
                                .handle_client_data(client_data, user_id)
                                .await
                                .map_err(internal_error)?;
                            Ok::<(), FlowyError>(())
                        };
                        match fut().await {
                            Ok(_) => {}
                            Err(e) => tracing::error!("[LocalWebSocket] error: {:?}", e),
                        }
                    }
                    Err(e) => tracing::error!("[LocalWebSocket] error: {}", e),
                }
            }
        });
    }
}

impl FlowyRawWebSocket for LocalWebSocket {
    fn initialize(&self) -> FutureResult<(), FlowyError> {
        let mut server_rx = self.server_rx.write().take().expect("Only take once");
        let receivers = self.receivers.clone();
        tokio::spawn(async move {
            while let Some(message) = server_rx.recv().await {
                match receivers.get(&message.module) {
                    None => tracing::error!("Can't find any handler for message: {:?}", message),
                    Some(handler) => handler.receive_message(message.clone()),
                }
            }
        });
        FutureResult::new(async { Ok(()) })
    }

    fn start_connect(&self, addr: String, user_id: String) -> FutureResult<(), FlowyError> {
        *self.user_id.write() = Some(user_id);
        self.spawn_client(addr);
        FutureResult::new(async { Ok(()) })
    }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> {
        self.state_sender.subscribe()
    }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn add_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        self.receivers.insert(receiver.source(), receiver);
        Ok(())
    }

    fn sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> {
        Ok(Arc::new(self.ws_sender.clone()))
    }
}

#[derive(Clone)]
struct LocalWSSender(broadcast::Sender<WebSocketRawMessage>);

impl std::default::Default for LocalWSSender {
    fn default() -> Self {
        let (tx, _) = broadcast::channel(16);
        Self(tx)
    }
}

impl FlowyWSSender for LocalWSSender {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError> {
        let _ = self.0.send(msg);
        Ok(())
    }
}

impl std::ops::Deref for LocalWSSender {
    type Target = broadcast::Sender<WebSocketRawMessage>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}
