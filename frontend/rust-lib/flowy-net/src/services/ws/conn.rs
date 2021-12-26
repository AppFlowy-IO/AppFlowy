use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::broadcast;

pub use flowy_error::FlowyError;
pub use lib_ws::{WSConnectState, WSMessageReceiver, WebScoketRawMessage};

pub trait FlowyWebSocket: Send + Sync {
    fn start_connect(&self, addr: String) -> FutureResult<(), FlowyError>;
    fn stop_connect(&self) -> FutureResult<(), FlowyError>;
    fn subscribe_connect_state(&self) -> broadcast::Receiver<WSConnectState>;
    fn reconnect(&self, count: usize) -> FutureResult<(), FlowyError>;
    fn add_message_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError>;
    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, FlowyError>;
}

pub trait FlowyWsSender: Send + Sync {
    fn send(&self, msg: WebScoketRawMessage) -> Result<(), FlowyError>;
}
