use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::*;
use flowy_error::{internal_error, FlowyError};
use lib_infra::future::FutureResult;
use lib_ws::{WSConnectState, WSMessageReceiver, WSModule, WebSocketRawMessage};

use crate::services::{
    local_ws::local_server::{spawn_server, LocalDocumentServer},
    ws_conn::{FlowyRawWebSocket, FlowyWSSender},
};
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{broadcast, broadcast::Receiver};

pub struct LocalWebSocket {
    receivers: Arc<DashMap<WSModule, Arc<dyn WSMessageReceiver>>>,
    state_sender: broadcast::Sender<WSConnectState>,
    ws_sender: LocalWSSender,
    server: Arc<LocalDocumentServer>,
}

impl std::default::Default for LocalWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let ws_sender = LocalWSSender::default();
        let receivers = Arc::new(DashMap::new());
        let server = spawn_server(receivers.clone());

        LocalWebSocket {
            receivers,
            state_sender,
            ws_sender,
            server,
        }
    }
}

impl LocalWebSocket {
    fn spawn_client(&self, _addr: String) {
        let mut ws_receiver = self.ws_sender.subscribe();
        let server = self.server.clone();
        tokio::spawn(async move {
            loop {
                match ws_receiver.recv().await {
                    Ok(message) => {
                        let fut = || async {
                            let bytes = Bytes::from(message.data);
                            let client_data = DocumentClientWSData::try_from(bytes).map_err(internal_error)?;
                            let _ = server.handle_client_data(client_data).await?;
                            Ok::<(), FlowyError>(())
                        };
                        match fut().await {
                            Ok(_) => {},
                            Err(e) => tracing::error!("[LocalWebSocket] error: {:?}", e),
                        }
                    },
                    Err(e) => tracing::error!("[LocalWebSocket] error: {}", e),
                }
            }
        });
    }
}

impl FlowyRawWebSocket for LocalWebSocket {
    fn start_connect(&self, addr: String) -> FutureResult<(), FlowyError> {
        self.spawn_client(addr);
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
