use crate::{connect::WsConnection, errors::WsError, WsMessage};
use flowy_net::errors::ServerError;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{ready, Stream};

use pin_project::pin_project;
use std::{
    collections::HashMap,
    future::Future,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};
use tokio::task::JoinHandle;
use tokio_tungstenite::{tungstenite::Message, MaybeTlsStream, WebSocketStream};

pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;
pub trait WsMessageHandler: Sync + Send + 'static {
    fn source(&self) -> String;
    fn receive_message(&self, msg: WsMessage);
}

pub struct WsController {
    sender: Option<Arc<WsSender>>,
    handlers: HashMap<String, Arc<dyn WsMessageHandler>>,
}

impl WsController {
    pub fn new() -> Self {
        let controller = Self {
            sender: None,
            handlers: HashMap::new(),
        };
        controller
    }

    pub fn add_handler(&mut self, handler: Arc<dyn WsMessageHandler>) -> Result<(), WsError> {
        let source = handler.source();
        if self.handlers.contains_key(&source) {
            return Err(WsError::duplicate_source());
        }
        self.handlers.insert(source, handler);
        Ok(())
    }

    pub fn connect(&mut self, addr: String) -> Result<JoinHandle<()>, ServerError> {
        log::debug!("🐴 ws connect: {}", &addr);
        let (connection, handlers) = self.make_connect(addr);
        Ok(tokio::spawn(async {
            tokio::select! {
                result = connection => {
                    match result {
                        Ok(stream) => {
                            tokio::spawn(stream).await;
                            // stream.start().await;
                        },
                        Err(e) => {
                            // TODO: retry?
                            log::error!("ws connect failed {:?}", e);
                        }
                    }
                },
                result = handlers => log::debug!("handlers completed {:?}", result),
            };
        }))
    }

    fn make_connect(&mut self, addr: String) -> (WsConnection, WsHandlers) {
        //                Stream                             User
        //               ┌───────────────┐                 ┌──────────────┐
        // ┌──────┐      │  ┌─────────┐  │    ┌────────┐   │  ┌────────┐  │
        // │Server│──────┼─▶│ ws_read │──┼───▶│ msg_tx │───┼─▶│ msg_rx │  │
        // └──────┘      │  └─────────┘  │    └────────┘   │  └────────┘  │
        //     ▲         │               │                 │              │
        //     │         │  ┌─────────┐  │    ┌────────┐   │  ┌────────┐  │
        //     └─────────┼──│ws_write │◀─┼────│ ws_rx  │◀──┼──│ ws_tx  │  │
        //               │  └─────────┘  │    └────────┘   │  └────────┘  │
        //               └───────────────┘                 └──────────────┘
        let (msg_tx, msg_rx) = futures_channel::mpsc::unbounded();
        let (ws_tx, ws_rx) = futures_channel::mpsc::unbounded();
        let handlers = self.handlers.clone();
        self.sender = Some(Arc::new(WsSender::new(ws_tx)));
        (WsConnection::new(msg_tx, ws_rx, addr), WsHandlers::new(handlers, msg_rx))
    }

    pub fn send_msg<T: Into<WsMessage>>(&self, msg: T) -> Result<(), WsError> {
        match self.sender.as_ref() {
            None => Err(WsError::internal().context("Should call make_connect first")),
            Some(sender) => sender.send(msg.into()),
        }
    }
}

#[pin_project]
pub struct WsHandlers {
    #[pin]
    msg_rx: MsgReceiver,
    handlers: HashMap<String, Arc<dyn WsMessageHandler>>,
}

impl WsHandlers {
    fn new(handlers: HashMap<String, Arc<dyn WsMessageHandler>>, msg_rx: MsgReceiver) -> Self { Self { msg_rx, handlers } }
}

impl Future for WsHandlers {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(self.as_mut().project().msg_rx.poll_next(cx)) {
                None => {
                    // log::debug!("🐴 ws handler done");
                    return Poll::Pending;
                },
                Some(message) => {
                    let message = WsMessage::from(message);
                    match self.handlers.get(&message.source) {
                        None => log::error!("Can't find any handler for message: {:?}", message),
                        Some(handler) => handler.receive_message(message.clone()),
                    }
                },
            }
        }
    }
}

struct WsSender {
    ws_tx: MsgSender,
}

impl WsSender {
    pub fn new(ws_tx: MsgSender) -> Self { Self { ws_tx } }

    pub fn send(&self, msg: WsMessage) -> Result<(), WsError> {
        let _ = self.ws_tx.unbounded_send(msg.into()).map_err(|e| WsError::internal().context(e))?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::WsController;

    #[tokio::test]
    async fn connect() {
        std::env::set_var("RUST_LOG", "Debug");
        env_logger::init();

        let mut controller = WsController::new();
        let addr = format!("{}/123", flowy_net::config::WS_ADDR.as_str());
        let (a, b) = controller.make_connect(addr);
        tokio::select! {
            r = a => println!("write completed {:?}", r),
            _ = b => println!("read completed"),
        };
    }
}
