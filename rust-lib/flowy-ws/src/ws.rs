use crate::{
    connect::{WsConnectionFuture, WsStream},
    errors::WsError,
    WsMessage,
    WsModule,
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_net::errors::ServerError;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{ready, Stream};
use parking_lot::RwLock;
use pin_project::pin_project;
use std::{
    convert::TryFrom,
    future::Future,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};
use tokio::sync::{broadcast, oneshot};
use tokio_tungstenite::tungstenite::{
    protocol::{frame::coding::CloseCode, CloseFrame},
    Message,
};

pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;
type Handlers = DashMap<WsModule, Arc<dyn WsMessageHandler>>;

pub trait WsMessageHandler: Sync + Send + 'static {
    fn source(&self) -> WsModule;
    fn receive_message(&self, msg: WsMessage);
}

#[derive(Clone)]
pub enum WsState {
    Init,
    Connected(Arc<WsSender>),
    Disconnected(WsError),
}

pub struct WsController {
    handlers: Handlers,
    state_notify: Arc<broadcast::Sender<WsState>>,
    sender: RwLock<Option<Arc<WsSender>>>,
}

impl WsController {
    pub fn new() -> Self {
        let (state_notify, _) = broadcast::channel(16);
        let controller = Self {
            handlers: DashMap::new(),
            sender: RwLock::new(None),
            state_notify: Arc::new(state_notify),
        };
        controller
    }

    pub fn add_handler(&self, handler: Arc<dyn WsMessageHandler>) -> Result<(), WsError> {
        let source = handler.source();
        if self.handlers.contains_key(&source) {
            log::error!("WsSource's {:?} is already registered", source);
        }
        self.handlers.insert(source, handler);
        Ok(())
    }

    pub async fn connect(&self, addr: String) -> Result<(), ServerError> {
        let (ret, rx) = oneshot::channel::<Result<(), ServerError>>();
        self._connect(addr.clone(), ret);
        rx.await?
    }

    #[allow(dead_code)]
    pub fn state_subscribe(&self) -> broadcast::Receiver<WsState> { self.state_notify.subscribe() }

    pub fn sender(&self) -> Result<Arc<WsSender>, WsError> {
        match &*self.sender.read() {
            None => Err(WsError::internal().context("WsSender is not initialized, should call connect first")),
            Some(sender) => Ok(sender.clone()),
        }
    }

    fn _connect(&self, addr: String, ret: oneshot::Sender<Result<(), ServerError>>) {
        log::debug!("🐴 ws connect: {}", &addr);
        let (connection, handlers) = self.make_connect(addr.clone());
        let state_notify = self.state_notify.clone();
        let sender = self
            .sender
            .read()
            .clone()
            .expect("Sender should be not empty after calling make_connect");
        tokio::spawn(async move {
            match connection.await {
                Ok(stream) => {
                    let _ = state_notify.send(WsState::Connected(sender));
                    let _ = ret.send(Ok(()));
                    spawn_stream_and_handlers(stream, handlers, state_notify).await;
                },
                Err(e) => {
                    let _ = state_notify.send(WsState::Disconnected(e.clone()));
                    let _ = ret.send(Err(ServerError::internal().context(e)));
                },
            }
        });
    }

    fn make_connect(&self, addr: String) -> (WsConnectionFuture, WsHandlerFuture) {
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
        *self.sender.write() = Some(Arc::new(WsSender { ws_tx }));
        (
            WsConnectionFuture::new(msg_tx, ws_rx, addr),
            WsHandlerFuture::new(handlers, msg_rx),
        )
    }
}

async fn spawn_stream_and_handlers(
    stream: WsStream,
    handlers: WsHandlerFuture,
    state_notify: Arc<broadcast::Sender<WsState>>,
) {
    tokio::select! {
        result = stream => {
            match result {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("ws stream error {:?}", e);
                    let _ = state_notify.send(WsState::Disconnected(e));
                }
            }
        },
        result = handlers => log::debug!("handlers completed {:?}", result),
    };
}

#[pin_project]
pub struct WsHandlerFuture {
    #[pin]
    msg_rx: MsgReceiver,
    // Opti: Hashmap would be better
    handlers: Handlers,
}

impl WsHandlerFuture {
    fn new(handlers: Handlers, msg_rx: MsgReceiver) -> Self { Self { msg_rx, handlers } }

    fn handler_ws_message(&self, message: Message) {
        match message {
            Message::Binary(bytes) => self.handle_binary_message(bytes),
            _ => {},
        }
    }

    fn handle_binary_message(&self, bytes: Vec<u8>) {
        let bytes = Bytes::from(bytes);
        match WsMessage::try_from(bytes) {
            Ok(message) => match self.handlers.get(&message.module) {
                None => log::error!("Can't find any handler for message: {:?}", message),
                Some(handler) => handler.receive_message(message.clone()),
            },
            Err(e) => {
                log::error!("Deserialize binary ws message failed: {:?}", e);
            },
        }
    }
}

impl Future for WsHandlerFuture {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(self.as_mut().project().msg_rx.poll_next(cx)) {
                None => {
                    return Poll::Ready(());
                },
                Some(message) => self.handler_ws_message(message),
            }
        }
    }
}

#[derive(Debug, Clone)]
pub struct WsSender {
    ws_tx: MsgSender,
}

impl WsSender {
    pub fn send_msg<T: Into<WsMessage>>(&self, msg: T) -> Result<(), WsError> {
        let msg = msg.into();
        let _ = self
            .ws_tx
            .unbounded_send(msg.into())
            .map_err(|e| WsError::internal().context(e))?;
        Ok(())
    }

    pub fn send_text(&self, source: &WsModule, text: &str) -> Result<(), WsError> {
        let msg = WsMessage {
            module: source.clone(),
            data: text.as_bytes().to_vec(),
        };
        self.send_msg(msg)
    }

    pub fn send_binary(&self, source: &WsModule, bytes: Vec<u8>) -> Result<(), WsError> {
        let msg = WsMessage {
            module: source.clone(),
            data: bytes,
        };
        self.send_msg(msg)
    }

    pub fn send_disconnect(&self, reason: &str) -> Result<(), WsError> {
        let frame = CloseFrame {
            code: CloseCode::Normal,
            reason: reason.to_owned().into(),
        };
        let msg = Message::Close(Some(frame));
        let _ = self
            .ws_tx
            .unbounded_send(msg)
            .map_err(|e| WsError::internal().context(e))?;
        Ok(())
    }
}

// #[cfg(test)]
// mod tests {
//     use super::WsController;
//
//     #[tokio::test]
//     async fn connect() {
//         std::env::set_var("RUST_LOG", "Debug");
//         env_logger::init();
//
//         let mut controller = WsController::new();
//         let addr = format!("{}/123", flowy_net::config::WS_ADDR.as_str());
//         let (a, b) = controller.make_connect(addr);
//         tokio::select! {
//             r = a => println!("write completed {:?}", r),
//             _ = b => println!("read completed"),
//         };
//     }
// }
