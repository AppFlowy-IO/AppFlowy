use crate::connection::{FlowyRawWebSocket, FlowyWebSocket};
use crate::WSErrorCode;
use futures_util::future::BoxFuture;
use lib_infra::future::FutureResult;
pub use lib_ws::{WSConnectState, WSMessageReceiver, WebSocketRawMessage};
use lib_ws::{WSController, WSSender};
use std::sync::Arc;
use tokio::sync::broadcast::Receiver;

impl FlowyRawWebSocket for Arc<WSController> {
  fn initialize(&self) -> FutureResult<(), WSErrorCode> {
    FutureResult::new(async { Ok(()) })
  }

  fn start_connect(&self, addr: String, _user_id: String) -> FutureResult<(), WSErrorCode> {
    let cloned_ws = self.clone();
    FutureResult::new(async move {
      cloned_ws.start(addr).await.map_err(internal_error)?;
      Ok(())
    })
  }

  fn stop_connect(&self) -> FutureResult<(), WSErrorCode> {
    let controller = self.clone();
    FutureResult::new(async move {
      controller.stop().await;
      Ok(())
    })
  }

  fn subscribe_connect_state(&self) -> BoxFuture<Receiver<WSConnectState>> {
    let cloned_ws = self.clone();
    Box::pin(async move { cloned_ws.subscribe_state().await })
  }

  fn reconnect(&self, count: usize) -> FutureResult<(), WSErrorCode> {
    let cloned_ws = self.clone();
    FutureResult::new(async move {
      cloned_ws.retry(count).await.map_err(internal_error)?;
      Ok(())
    })
  }

  fn add_msg_receiver(&self, receiver: Arc<dyn WSMessageReceiver>) -> Result<(), WSErrorCode> {
    self
      .add_ws_message_receiver(receiver)
      .map_err(internal_error)?;
    Ok(())
  }

  fn ws_msg_sender(&self) -> FutureResult<Option<Arc<dyn FlowyWebSocket>>, WSErrorCode> {
    let cloned_self = self.clone();
    FutureResult::new(async move {
      match cloned_self
        .ws_message_sender()
        .await
        .map_err(internal_error)?
      {
        None => Ok(None),
        Some(sender) => {
          let sender = sender as Arc<dyn FlowyWebSocket>;
          Ok(Some(sender))
        },
      }
    })
  }
}

impl FlowyWebSocket for WSSender {
  fn send(&self, msg: WebSocketRawMessage) -> Result<(), WSErrorCode> {
    self.send_msg(msg).map_err(internal_error)?;
    Ok(())
  }
}

fn internal_error<T>(_e: T) -> WSErrorCode
where
  T: std::fmt::Debug,
{
  WSErrorCode::Internal
}
