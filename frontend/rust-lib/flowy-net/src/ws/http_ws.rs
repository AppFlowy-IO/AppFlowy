use crate::ws::connection::{FlowyRawWebSocket, FlowyWebSocket};
use flowy_error::internal_error;
pub use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
pub use lib_ws::{WSConnectState, WSMessageReceiver, WebSocketRawMessage};
use lib_ws::{WSController, WSSender};

use std::sync::Arc;
use tokio::sync::broadcast::Receiver;

impl FlowyRawWebSocket for Arc<WSController> {
    fn initialize(&self) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    fn start_connect(&self, addr: String, _user_id: String) -> FutureResult<(), FlowyError> {
        let cloned_ws = self.clone();
        FutureResult::new(async move {
            let _ = cloned_ws.start(addr).await.map_err(internal_error)?;
            Ok(())
        })
    }

    fn stop_connect(&self) -> FutureResult<(), FlowyError> {
        let controller = self.clone();
        FutureResult::new(async move {
            controller.stop().await;
            Ok(())
        })
    }

    fn subscribe_connect_state(&self) -> Receiver<WSConnectState> { self.subscribe_state() }

    fn reconnect(&self, count: usize) -> FutureResult<(), FlowyError> {
        let cloned_ws = self.clone();
        FutureResult::new(async move {
            let _ = cloned_ws.retry(count).await.map_err(internal_error)?;
            Ok(())
        })
    }

    fn add_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), FlowyError> {
        let _ = self.add_ws_message_receiver(receiver).map_err(internal_error)?;
        Ok(())
    }

    fn sender(&self) -> Result<Arc<dyn FlowyWebSocket>, FlowyError> {
        let sender = self.ws_message_sender().map_err(internal_error)?;
        Ok(sender)
    }
}

impl FlowyWebSocket for WSSender {
    fn send(&self, msg: WebSocketRawMessage) -> Result<(), FlowyError> {
        let _ = self.send_msg(msg).map_err(internal_error)?;
        Ok(())
    }
}
