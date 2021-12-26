use crate::services::ws::{
    FlowyError,
    FlowyWebSocket,
    FlowyWsSender,
    WSConnectState,
    WSMessageReceiver,
    WebScoketRawMessage,
};
use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::{broadcast, broadcast::Receiver};

pub(crate) struct LocalWebSocket {
    state_sender: broadcast::Sender<WSConnectState>,
    ws_sender: broadcast::Sender<WebScoketRawMessage>,
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

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.state_sender.subscribe() }

    fn reconnect(&self, _count: usize) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn add_message_receiver(&self, _handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> { Ok(()) }

    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, FlowyError> { Ok(Arc::new(self.ws_sender.clone())) }
}

impl FlowyWsSender for broadcast::Sender<WebScoketRawMessage> {
    fn send(&self, msg: WebScoketRawMessage) -> Result<(), FlowyError> {
        let _ = self.send(msg);
        Ok(())
    }
}
