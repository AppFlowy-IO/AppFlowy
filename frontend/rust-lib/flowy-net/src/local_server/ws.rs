use crate::ws::connection::{FlowyRawWebSocket, FlowyWebSocket};
use dashmap::DashMap;
use flowy_error::FlowyError;
use futures_util::future::BoxFuture;
use lib_infra::future::FutureResult;
use lib_ws::{WSChannel, WSConnectState, WSMessageReceiver, WebSocketRawMessage};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver, mpsc::UnboundedReceiver};

pub struct LocalWebSocket {
    user_id: Arc<RwLock<Option<String>>>,
    receivers: Arc<DashMap<WSChannel, Arc<dyn WSMessageReceiver>>>,
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
                match receivers.get(&message.channel) {
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

    fn subscribe_connect_state(&self) -> BoxFuture<Receiver<WSConnectState>> {
        let subscribe = self.state_sender.subscribe();
        Box::pin(async move { subscribe })
    }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_msg_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        tracing::trace!("Local web socket add ws receiver: {:?}", receiver.source());
        self.receivers.insert(receiver.source(), receiver);
        Ok(())
    }

    fn ws_msg_sender(&self) -> FutureResult<Option<Arc<dyn FlowyWebSocket>>, FlowyError> {
        let ws: Arc<dyn FlowyWebSocket> = Arc::new(LocalWebSocketAdaptor(self.server_ws_sender.clone()));
        FutureResult::new(async move { Ok(Some(ws)) })
    }
}

#[derive(Clone)]
struct LocalWebSocketAdaptor(broadcast::Sender<WebSocketRawMessage>);

impl FlowyWebSocket for LocalWebSocketAdaptor {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError> {
        let _ = self.0.send(msg);
        Ok(())
    }
}
