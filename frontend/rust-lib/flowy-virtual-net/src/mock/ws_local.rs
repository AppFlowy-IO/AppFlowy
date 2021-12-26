use crate::mock::server::MockDocServer;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::*;
use flowy_net::services::ws::*;
use lib_infra::future::FutureResult;
use lib_ws::{WSModule, WebSocketRawMessage};
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::{broadcast, broadcast::Receiver};

pub struct MockWebSocket {
    receivers: Arc<DashMap<WSModule, Arc<dyn WSMessageReceiver>>>,
    state_sender: broadcast::Sender<WSConnectState>,
    ws_sender: MockWSSender,
    is_stop: Arc<RwLock<bool>>,
    server: Arc<MockDocServer>,
}

impl std::default::Default for MockWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let (ws_sender, _) = broadcast::channel(16);
        let server = Arc::new(MockDocServer::default());
        MockWebSocket {
            receivers: Arc::new(DashMap::new()),
            state_sender,
            ws_sender: MockWSSender(ws_sender),
            is_stop: Arc::new(RwLock::new(false)),
            server,
        }
    }
}

impl FlowyWebSocket for MockWebSocket {
    fn start_connect(&self, _addr: String) -> FutureResult<(), FlowyError> {
        *self.is_stop.write() = false;

        let mut ws_receiver = self.ws_sender.subscribe();
        let receivers = self.receivers.clone();
        let is_stop = self.is_stop.clone();
        let server = self.server.clone();
        tokio::spawn(async move {
            while let Ok(message) = ws_receiver.recv().await {
                if *is_stop.read() {
                    // do nothing
                } else {
                    let ws_data = DocumentClientWSData::try_from(Bytes::from(message.data.clone())).unwrap();

                    if let Some(mut rx) = server.handle_client_data(ws_data).await {
                        let new_ws_message = rx.recv().await.unwrap();
                        match receivers.get(&new_ws_message.module) {
                            None => tracing::error!("Can't find any handler for message: {:?}", new_ws_message),
                            Some(handler) => handler.receive_message(new_ws_message.clone()),
                        }
                    }
                }
            }
        });

        FutureResult::new(async { Ok(()) })
    }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> {
        *self.is_stop.write() = true;
        FutureResult::new(async { Ok(()) })
    }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_message_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        self.receivers.insert(handler.source(), handler);
        Ok(())
    }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> { Ok(Arc::new(self.ws_sender.clone())) }
}

#[derive(Clone)]
pub struct MockWSSender(broadcast::Sender<WebSocketRawMessage>);

impl FlowyWSSender for MockWSSender {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError> {
        let _ = self.0.send(msg);
        Ok(())
    }
}

impl std::ops::Deref for MockWSSender {
    type Target = broadcast::Sender<WebSocketRawMessage>;

    fn deref(&self) -> &Self::Target { &self.0 }
}
