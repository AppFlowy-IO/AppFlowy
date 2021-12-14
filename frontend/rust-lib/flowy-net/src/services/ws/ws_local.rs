use crate::services::ws::{FlowyError, FlowyWebSocket, FlowyWsSender, WsConnectState, WsMessage, WsMessageHandler};
use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver};

pub(crate) struct LocalWebSocket {
    state_sender: broadcast::Sender<WsConnectState>,
    ws_sender: broadcast::Sender<WsMessage>,
}

impl std::default::Default for LocalWebSocket {
    fn default() -> Self {
        let (state_sender, _) = broadcast::channel(16);
        let (ws_sender, _) = broadcast::channel(16);
        LocalWebSocket {
            state_sender,
            ws_sender,
        }
    }
}

impl FlowyWebSocket for Arc<LocalWebSocket> {
    fn start_connect(&self, _addr: String) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn subscribe_connect_state(&self) -> Receiver<WsConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_handler(&self, _handler: Arc<dyn WsMessageHandler>) -> Result<(), FlowyError> { Ok(()) }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, FlowyError> { Ok(Arc::new(self.ws_sender.clone())) }
}

impl FlowyWsSender for broadcast::Sender<WsMessage> {
    fn send(&self, msg: WsMessage) -> Result<(), FlowyError> {
        let _ = self.send(msg);
        Ok(())
    }
}
