use crate::ws::{
    connection::{FlowyRawWebSocket, FlowyWSSender},
    local::local_server::LocalDocumentServer,
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::*;
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;
use lib_ws::{WSConnectState, WSMessageReceiver, WSModule, WebSocketRawMessage};
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{broadcast, broadcast::Receiver, mpsc, mpsc::UnboundedReceiver};

pub struct LocalWebSocket {
    receivers: Arc<DashMap<WSModule, Arc<dyn WSMessageReceiver>>>,
    state_sender: broadcast::Sender<WSConnectState>,
    // LocalWSSender uses the mpsc::channel sender to simulate the web socket. It spawns a receiver that uses the
    // LocalDocumentServer  to handle the message. The server will send the WebSocketRawMessage messages that will
    // be handled by the WebSocketRawMessage receivers.
    ws_sender: LocalWSSender,
    local_server: Arc<LocalDocumentServer>,
    local_server_rx: RwLock<Option<UnboundedReceiver<WebSocketRawMessage>>>,
    local_server_stop_tx: RwLock<Option<mpsc::Sender<()>>>,
    user_id: Arc<RwLock<Option<String>>>,
}

impl std::default::Default for LocalWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let ws_sender = LocalWSSender::default();
        let receivers = Arc::new(DashMap::new());

        let (server_tx, server_rx) = mpsc::unbounded_channel();
        let local_server = Arc::new(LocalDocumentServer::new(server_tx));
        let local_server_rx = RwLock::new(Some(server_rx));
        let local_server_stop_tx = RwLock::new(None);
        let user_id = Arc::new(RwLock::new(None));

        LocalWebSocket {
            receivers,
            state_sender,
            ws_sender,
            local_server,
            local_server_rx,
            local_server_stop_tx,
            user_id,
        }
    }
}

impl LocalWebSocket {
    fn restart_ws_receiver(&self) -> mpsc::Receiver<()> {
        if let Some(stop_tx) = self.local_server_stop_tx.read().clone() {
            tokio::spawn(async move {
                let _ = stop_tx.send(()).await;
            });
        }
        let (stop_tx, stop_rx) = mpsc::channel::<()>(1);
        *self.local_server_stop_tx.write() = Some(stop_tx);
        stop_rx
    }

    fn spawn_client_ws_receiver(&self, _addr: String) {
        let mut ws_receiver = self.ws_sender.subscribe();
        let local_server = self.local_server.clone();
        let user_id = self.user_id.clone();
        let mut stop_rx = self.restart_ws_receiver();
        tokio::spawn(async move {
            loop {
                tokio::select! {
                    result = ws_receiver.recv() => {
                        match result {
                            Ok(message) => {
                                let user_id = user_id.read().clone();
                                handle_ws_raw_message(user_id, &local_server, message).await;
                            },
                            Err(e) => tracing::error!("[LocalWebSocket] error: {}", e),
                        }
                    }
                    _ = stop_rx.recv() => {
                        break
                    },
                }
            }
        });
    }
}

async fn handle_ws_raw_message(
    user_id: Option<String>,
    local_server: &Arc<LocalDocumentServer>,
    message: WebSocketRawMessage,
) {
    let f = || async {
        match user_id {
            None => Ok(()),
            Some(user_id) => {
                let bytes = Bytes::from(message.data);
                let client_data = DocumentClientWSData::try_from(bytes).map_err(internal_error)?;
                let _ = local_server.handle_client_data(client_data, user_id).await?;
                Ok::<(), FlowyError>(())
            },
        }
    };
    if let Err(e) = f().await {
        tracing::error!("[LocalWebSocket] error: {:?}", e);
    }
}

impl FlowyRawWebSocket for LocalWebSocket {
    fn initialize(&self) -> FutureResult<(), FlowyError> {
        let mut server_rx = self.local_server_rx.write().take().expect("Only take once");
        let receivers = self.receivers.clone();
        tokio::spawn(async move {
            while let Some(message) = server_rx.recv().await {
                match receivers.get(&message.module) {
                    None => tracing::error!("Can't find any handler for message: {:?}", message),
                    Some(receiver) => receiver.receive_message(message.clone()),
                }
            }
        });
        FutureResult::new(async { Ok(()) })
    }

    fn start_connect(&self, addr: String, user_id: String) -> FutureResult<(), FlowyError> {
        *self.user_id.write() = Some(user_id);
        self.spawn_client_ws_receiver(addr);
        FutureResult::new(async { Ok(()) })
    }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        self.receivers.insert(receiver.source(), receiver);
        Ok(())
    }

    fn sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> { Ok(Arc::new(self.ws_sender.clone())) }
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

    fn deref(&self) -> &Self::Target { &self.0 }
}
