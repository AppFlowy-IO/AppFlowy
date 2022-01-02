use flowy_net::services::ws::{
    FlowyError,
    FlowyWSSender,
    FlowyWebSocket,
    WSConnectState,
    WSMessageReceiver,
    WebSocketRawMessage,
};
use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver};

pub(crate) struct LocalWebSocket {
    state_sender: broadcast::Sender<WSConnectState>,
    ws_sender: LocalWSSender,
}

impl std::default::Default for LocalWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let (ws_sender, _) = broadcast::channel(16);
        LocalWebSocket {
            state_sender,
            ws_sender: LocalWSSender(ws_sender),
        }
    }
}

impl FlowyWebSocket for LocalWebSocket {
    fn start_connect(&self, _addr: String) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_message_receiver(&self, _handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> { Ok(()) }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWSSender>, FlowyError> { Ok(Arc::new(self.ws_sender.clone())) }
}

#[derive(Clone)]
pub struct LocalWSSender(broadcast::Sender<WebSocketRawMessage>);
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
