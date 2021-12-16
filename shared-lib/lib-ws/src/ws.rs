#![allow(clippy::type_complexity)]
use crate::{
    connect::{WsConnectionFuture, WsStream},
    errors::WsError,
    WsMessage,
    WsModule,
};
use backend_service::errors::ServerError;
use bytes::Bytes;
use dashmap::DashMap;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{ready, Stream};
use lib_infra::retry::{Action, FixedInterval, Retry};
use parking_lot::RwLock;
use pin_project::pin_project;
use std::{
    convert::TryFrom,
    fmt::Formatter,
    future::Future,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
    time::Duration,
};
use tokio::sync::{broadcast, oneshot};
use tokio_tungstenite::tungstenite::{
    protocol::{frame::coding::CloseCode, CloseFrame},
    Message,
};

pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;
type Handlers = DashMap<WsModule, Arc<dyn WsMessageReceiver>>;

pub trait WsMessageReceiver: Sync + Send + 'static {
    fn source(&self) -> WsModule;
    fn receive_message(&self, msg: WsMessage);
}

pub struct WsController {
    handlers: Handlers,
    state_notify: Arc<broadcast::Sender<WsConnectState>>,
    sender_ctrl: Arc<RwLock<WsSenderController>>,
    addr: Arc<RwLock<Option<String>>>,
}

impl std::default::Default for WsController {
    fn default() -> Self {
        let (state_notify, _) = broadcast::channel(16);
        Self {
            handlers: DashMap::new(),
            sender_ctrl: Arc::new(RwLock::new(WsSenderController::default())),
            state_notify: Arc::new(state_notify),
            addr: Arc::new(RwLock::new(None)),
        }
    }
}

impl WsController {
    pub fn new() -> Self { WsController::default() }

    pub fn add_receiver(&self, handler: Arc<dyn WsMessageReceiver>) -> Result<(), WsError> {
        let source = handler.source();
        if self.handlers.contains_key(&source) {
            log::error!("WsSource's {:?} is already registered", source);
        }
        self.handlers.insert(source, handler);
        Ok(())
    }

    pub async fn start(&self, addr: String) -> Result<(), ServerError> {
        *self.addr.write() = Some(addr.clone());
        let strategy = FixedInterval::from_millis(5000).take(3);
        self.connect(addr, strategy).await
    }

    pub async fn stop(&self) { self.sender_ctrl.write().set_state(WsConnectState::Disconnected); }

    async fn connect<T, I>(&self, addr: String, strategy: T) -> Result<(), ServerError>
    where
        T: IntoIterator<IntoIter = I, Item = Duration>,
        I: Iterator<Item = Duration> + Send + 'static,
    {
        let (ret, rx) = oneshot::channel::<Result<(), ServerError>>();
        *self.addr.write() = Some(addr.clone());
        let action = WsConnectAction {
            addr,
            handlers: self.handlers.clone(),
        };

        let retry = Retry::spawn(strategy, action);
        let sender_ctrl = self.sender_ctrl.clone();
        sender_ctrl.write().set_state(WsConnectState::Connecting);

        tokio::spawn(async move {
            match retry.await {
                Ok(result) => {
                    let WsConnectResult {
                        stream,
                        handlers_fut,
                        sender,
                    } = result;
                    sender_ctrl.write().set_sender(sender);
                    sender_ctrl.write().set_state(WsConnectState::Connected);
                    let _ = ret.send(Ok(()));
                    spawn_stream_and_handlers(stream, handlers_fut, sender_ctrl.clone()).await;
                },
                Err(e) => {
                    sender_ctrl.write().set_error(e.clone());
                    let _ = ret.send(Err(ServerError::internal().context(e)));
                },
            }
        });

        rx.await?
    }

    pub async fn retry(&self, count: usize) -> Result<(), ServerError> {
        if self.sender_ctrl.read().is_connecting() {
            return Ok(());
        }

        let strategy = FixedInterval::from_millis(5000).take(count);
        let addr = self
            .addr
            .read()
            .as_ref()
            .expect("must call start_connect first")
            .clone();

        self.connect(addr, strategy).await
    }

    pub fn subscribe_state(&self) -> broadcast::Receiver<WsConnectState> { self.state_notify.subscribe() }

    pub fn sender(&self) -> Result<Arc<WsSender>, WsError> {
        match self.sender_ctrl.read().sender() {
            None => Err(WsError::internal().context("WsSender is not initialized, should call connect first")),
            Some(sender) => Ok(sender),
        }
    }
}

async fn spawn_stream_and_handlers(
    stream: WsStream,
    handlers: WsHandlerFuture,
    sender_ctrl: Arc<RwLock<WsSenderController>>,
) {
    tokio::select! {
        result = stream => {
            if let Err(e) = result {
                sender_ctrl.write().set_error(e);
            }
        },
        result = handlers => tracing::debug!("handlers completed {:?}", result),
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
        if let Message::Binary(bytes) = message {
            self.handle_binary_message(bytes)
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

struct WsConnectAction {
    addr: String,
    handlers: Handlers,
}

impl Action for WsConnectAction {
    type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send + Sync>>;
    type Item = WsConnectResult;
    type Error = WsError;

    fn run(&mut self) -> Self::Future {
        let addr = self.addr.clone();
        let handlers = self.handlers.clone();
        Box::pin(WsConnectActionFut::new(addr, handlers))
    }
}

struct WsConnectResult {
    stream: WsStream,
    handlers_fut: WsHandlerFuture,
    sender: WsSender,
}

#[pin_project]
struct WsConnectActionFut {
    addr: String,
    #[pin]
    conn: WsConnectionFuture,
    handlers_fut: Option<WsHandlerFuture>,
    sender: Option<WsSender>,
}

impl WsConnectActionFut {
    fn new(addr: String, handlers: Handlers) -> Self {
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
        let sender = WsSender { ws_tx };
        let handlers_fut = WsHandlerFuture::new(handlers, msg_rx);
        let conn = WsConnectionFuture::new(msg_tx, ws_rx, addr.clone());
        Self {
            addr,
            conn,
            handlers_fut: Some(handlers_fut),
            sender: Some(sender),
        }
    }
}

impl Future for WsConnectActionFut {
    type Output = Result<WsConnectResult, WsError>;
    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let mut this = self.project();
        match ready!(this.conn.as_mut().poll(cx)) {
            Ok(stream) => {
                let handlers_fut = this.handlers_fut.take().expect("Only take once");
                let sender = this.sender.take().expect("Only take once");
                Poll::Ready(Ok(WsConnectResult {
                    stream,
                    handlers_fut,
                    sender,
                }))
            },
            Err(e) => Poll::Ready(Err(e)),
        }
    }
}

#[derive(Clone, Eq, PartialEq)]
pub enum WsConnectState {
    Init,
    Connecting,
    Connected,
    Disconnected,
}

impl std::fmt::Display for WsConnectState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            WsConnectState::Init => f.write_str("Init"),
            WsConnectState::Connected => f.write_str("Connecting"),
            WsConnectState::Connecting => f.write_str("Connected"),
            WsConnectState::Disconnected => f.write_str("Disconnected"),
        }
    }
}

impl std::fmt::Debug for WsConnectState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str(&format!("{}", self)) }
}

struct WsSenderController {
    state: WsConnectState,
    state_notify: Arc<broadcast::Sender<WsConnectState>>,
    sender: Option<Arc<WsSender>>,
}

impl WsSenderController {
    fn set_sender(&mut self, sender: WsSender) { self.sender = Some(Arc::new(sender)); }

    fn set_state(&mut self, state: WsConnectState) {
        if state != WsConnectState::Connected {
            self.sender = None;
        }

        self.state = state;
        let _ = self.state_notify.send(self.state.clone());
    }

    fn set_error(&mut self, error: WsError) {
        log::error!("{:?}", error);
        self.set_state(WsConnectState::Disconnected);
    }

    fn sender(&self) -> Option<Arc<WsSender>> { self.sender.clone() }

    fn is_connecting(&self) -> bool { self.state == WsConnectState::Connecting }

    #[allow(dead_code)]
    fn is_connected(&self) -> bool { self.state == WsConnectState::Connected }
}

impl std::default::Default for WsSenderController {
    fn default() -> Self {
        let (state_notify, _) = broadcast::channel(16);
        WsSenderController {
            state: WsConnectState::Init,
            state_notify: Arc::new(state_notify),
            sender: None,
        }
    }
}
