use lib_infra::future::FutureResult;
use std::sync::Arc;
use tokio::sync::broadcast;

pub use flowy_error::FlowyError;
pub use lib_ws::{WsConnectState, WsMessage, WsMessageHandler};

pub trait FlowyWebSocket: Send + Sync {
    fn start_connect(&self, addr: String) -> FutureResult<(), FlowyError>;
    fn conn_state_subscribe(&self) -> broadcast::Receiver<WsConnectState>;
    fn reconnect(&self, count: usize) -> FutureResult<(), FlowyError>;
    fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), FlowyError>;
    fn ws_sender(&self) -> Result<Arc<dyn FlowyWsSender>, FlowyError>;
}

pub trait FlowyWsSender: Send + Sync {
    fn send(&self, msg: WsMessage) -> Result<(), FlowyError>;
}
