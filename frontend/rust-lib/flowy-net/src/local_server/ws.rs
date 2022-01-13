use crate::ws::connection::{FlowyRawWebSocket, FlowyWSSender};
use dashmap::DashMap;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use lib_ws::{WSConnectState, WSMessageReceiver, WSModule, WebSocketRawMessage};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver, mpsc::UnboundedReceiver};

pub struct LocalWebSocket {
    user_id: Arc<RwLock<Option<String>>>,
    receivers: Arc<DashMap<WSModule, Arc<dyn WSMessageReceiver>>>,
    state_sender: broadcast::Sender<WSConnectState>,
    server_ws_receiver: RwLock<Option<UnboundedReceiver<WebSocketRawMessage>>>,
    server_ws_sender: broadcast::Sender<WebSocketRawMessage>,
}

impl LocalWebSocket {
    pub fn new(
        server_ws_receiver: UnboundedReceiver<WebSocketRawMessage>,
        server_ws_sender: broadcast::Sender<WebSocketRawMessage>,
    ) -> Self {
        let user_id = Arc::new(RwLock::new(None));
        let receivers = Arc::new(DashMap::new());
        let server_ws_receiver = RwLock::new(Some(server_ws_receiver));
        let (state_sender, _) = broadcast::channel(16);
        LocalWebSocket {
            user_id,
            receivers,
            state_sender,
            server_ws_receiver,
            server_ws_sender,
        }
    }
}

impl FlowyRawWebSocket for LocalWebSocket {
    fn initialize(&self) -> FutureResult<(), FlowyError> {
        let mut server_ws_receiver = self.server_ws_receiver.write().take().expect("Only take once");
        let receivers = self.receivers.clone();
        tokio::spawn(async move {
            while let Some(message) = server_ws_receiver.recv().await {
                match receivers.get(&message.module) {
                    None => tracing::error!("Can't find any handler for message: {:?}", message),
                    Some(receiver) => receiver.receive_message(message.clone()),
                }
            }
        });
        FutureResult::new(async { Ok(()) })
    }

    fn start_connect(&self, _addr: String, user_id: String) -> FutureResult<(), FlowyError> {
        *self.user_id.write() = Some(user_id);
        FutureResult::new(async { Ok(()) })
    }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        self.receivers.insert(receiver.source(), receiver);
        Ok(())
    }

    fn sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> {
        let ws = LocalWebSocketAdaptor(self.server_ws_sender.clone());
        Ok(Arc::new(ws))
    }
}

#[derive(Clone)]
struct LocalWebSocketAdaptor(broadcast::Sender<WebSocketRawMessage>);

impl FlowyWSSender for LocalWebSocketAdaptor {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError> {
        let _ = self.0.send(msg);
        Ok(())
    }
}
