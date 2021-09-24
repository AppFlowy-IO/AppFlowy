use crate::{
    connect::{Retry, WsConnectionFuture},
    errors::WsError,
    WsMessage,
    WsModule,
};
use bytes::Bytes;
use flowy_net::errors::ServerError;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{future::BoxFuture, ready, Stream};
use pin_project::pin_project;
use std::{
    collections::HashMap,
    convert::{Infallible, TryFrom},
    future::Future,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};
use tokio::{sync::RwLock, task::JoinHandle};
use tokio_tungstenite::tungstenite::{
    protocol::{frame::coding::CloseCode, CloseFrame},
    Message,
};

pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;
pub trait WsMessageHandler: Sync + Send + 'static {
    fn source(&self) -> WsModule;
    fn receive_message(&self, msg: WsMessage);
}

type NotifyCallback = Arc<dyn Fn(&WsState) + Send + Sync + 'static>;
struct WsStateNotify {
    #[allow(dead_code)]
    state: WsState,
    callback: Option<NotifyCallback>,
}

impl WsStateNotify {
    fn update_state(&mut self, state: WsState) {
        if let Some(f) = &self.callback {
            f(&state);
        }
        self.state = state;
    }
}

pub enum WsState {
    Init,
    Connected(Arc<WsSender>),
    Disconnected(WsError),
}

pub struct WsController {
    handlers: HashMap<WsModule, Arc<dyn WsMessageHandler>>,
    state_notify: Arc<RwLock<WsStateNotify>>,
    #[allow(dead_code)]
    addr: Option<String>,
    sender: Option<Arc<WsSender>>,
}

impl WsController {
    pub fn new() -> Self {
        let state_notify = Arc::new(RwLock::new(WsStateNotify {
            state: WsState::Init,
            callback: None,
        }));

        let controller = Self {
            handlers: HashMap::new(),
            state_notify,
            addr: None,
            sender: None,
        };
        controller
    }

    pub async fn state_callback<SC>(&self, callback: SC)
    where
        SC: Fn(&WsState) + Send + Sync + 'static,
    {
        (self.state_notify.write().await).callback = Some(Arc::new(callback));
    }

    pub fn add_handler(&mut self, handler: Arc<dyn WsMessageHandler>) -> Result<(), WsError> {
        let source = handler.source();
        if self.handlers.contains_key(&source) {
            log::error!("WsSource's {:?} is already registered", source);
        }
        self.handlers.insert(source, handler);
        Ok(())
    }

    pub fn connect(&mut self, addr: String) -> Result<JoinHandle<()>, ServerError> { self._connect(addr.clone(), None) }

    pub fn connect_with_retry<F>(&mut self, addr: String, retry: Retry<F>) -> Result<JoinHandle<()>, ServerError>
    where
        F: Fn(&str) + Send + Sync + 'static,
    {
        self._connect(addr, Some(Box::pin(async { retry.await })))
    }

    pub fn get_sender(&self) -> Result<Arc<WsSender>, WsError> {
        match &self.sender {
            None => Err(WsError::internal().context("WsSender is not initialized")),
            Some(sender) => Ok(sender.clone()),
        }
    }

    fn _connect(&mut self, addr: String, retry: Option<BoxFuture<'static, ()>>) -> Result<JoinHandle<()>, ServerError> {
        log::debug!("🐴 ws connect: {}", &addr);
        let (connection, handlers) = self.make_connect(addr.clone());
        let state_notify = self.state_notify.clone();
        let sender = self.sender.clone().expect("Sender should be not empty after calling make_connect");
        Ok(tokio::spawn(async move {
            match connection.await {
                Ok(stream) => {
                    state_notify.write().await.update_state(WsState::Connected(sender));
                    tokio::select! {
                        result = stream => {
                            match result {
                                Ok(_) => {},
                                Err(e) => {
                                    // TODO: retry?
                                    log::error!("ws stream error {:?}", e);
                                    state_notify.write().await.update_state(WsState::Disconnected(e));
                                }
                            }
                        },
                        result = handlers => log::debug!("handlers completed {:?}", result),
                    };
                },
                Err(e) => {
                    log::error!("ws connect {} failed {:?}", addr, e);
                    state_notify.write().await.update_state(WsState::Disconnected(e));
                    if let Some(retry) = retry {
                        tokio::spawn(retry);
                    }
                },
            }
        }))
    }

    fn make_connect(&mut self, addr: String) -> (WsConnectionFuture, WsHandlerFuture) {
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
        self.sender = Some(Arc::new(WsSender { ws_tx }));
        self.addr = Some(addr.clone());
        (WsConnectionFuture::new(msg_tx, ws_rx, addr), WsHandlerFuture::new(handlers, msg_rx))
    }
}

#[pin_project]
pub struct WsHandlerFuture {
    #[pin]
    msg_rx: MsgReceiver,
    handlers: HashMap<WsModule, Arc<dyn WsMessageHandler>>,
}

impl WsHandlerFuture {
    fn new(handlers: HashMap<WsModule, Arc<dyn WsMessageHandler>>, msg_rx: MsgReceiver) -> Self { Self { msg_rx, handlers } }

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
        let _ = self.ws_tx.unbounded_send(msg.into()).map_err(|e| WsError::internal().context(e))?;
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
        let _ = self.ws_tx.unbounded_send(msg).map_err(|e| WsError::internal().context(e))?;
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
