#![allow(clippy::type_complexity)]
use crate::{
    connect::{WSConnectionFuture, WSStream},
    errors::WSError,
    WSModule,
    WebScoketRawMessage,
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
type Handlers = DashMap<WSModule, Arc<dyn WSMessageReceiver>>;

pub trait WSMessageReceiver: Sync + Send + 'static {
    fn source(&self) -> WSModule;
    fn receive_message(&self, msg: WebScoketRawMessage);
}

pub struct WSController {
    handlers: Handlers,
    state_notify: Arc<broadcast::Sender<WSConnectState>>,
    sender_ctrl: Arc<RwLock<WSSenderController>>,
    addr: Arc<RwLock<Option<String>>>,
}

impl std::default::Default for WSController {
    fn default() -> Self {
        let (state_notify, _) = broadcast::channel(16);
        Self {
            handlers: DashMap::new(),
            sender_ctrl: Arc::new(RwLock::new(WSSenderController::default())),
            state_notify: Arc::new(state_notify),
            addr: Arc::new(RwLock::new(None)),
        }
    }
}

impl WSController {
    pub fn new() -> Self { WSController::default() }

    pub fn add_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), WSError> {
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

    pub async fn stop(&self) { self.sender_ctrl.write().set_state(WSConnectState::Disconnected); }

    async fn connect<T, I>(&self, addr: String, strategy: T) -> Result<(), ServerError>
    where
        T: IntoIterator<IntoIter = I, Item = Duration>,
        I: Iterator<Item = Duration> + Send + 'static,
    {
        let (ret, rx) = oneshot::channel::<Result<(), ServerError>>();
        *self.addr.write() = Some(addr.clone());
        let action = WSConnectAction {
            addr,
            handlers: self.handlers.clone(),
        };

        let retry = Retry::spawn(strategy, action);
        let sender_ctrl = self.sender_ctrl.clone();
        sender_ctrl.write().set_state(WSConnectState::Connecting);

        tokio::spawn(async move {
            match retry.await {
                Ok(result) => {
                    let WSConnectResult {
                        stream,
                        handlers_fut,
                        sender,
                    } = result;
                    sender_ctrl.write().set_sender(sender);
                    sender_ctrl.write().set_state(WSConnectState::Connected);
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

    pub fn subscribe_state(&self) -> broadcast::Receiver<WSConnectState> { self.state_notify.subscribe() }

    pub fn sender(&self) -> Result<Arc<WSSender>, WSError> {
        match self.sender_ctrl.read().sender() {
            None => Err(WSError::internal().context("WsSender is not initialized, should call connect first")),
            Some(sender) => Ok(sender),
        }
    }
}

async fn spawn_stream_and_handlers(
    stream: WSStream,
    handlers: WSHandlerFuture,
    sender_ctrl: Arc<RwLock<WSSenderController>>,
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
pub struct WSHandlerFuture {
    #[pin]
    msg_rx: MsgReceiver,
    // Opti: Hashmap would be better
    handlers: Handlers,
}

impl WSHandlerFuture {
    fn new(handlers: Handlers, msg_rx: MsgReceiver) -> Self { Self { msg_rx, handlers } }

    fn handler_ws_message(&self, message: Message) {
        if let Message::Binary(bytes) = message {
            self.handle_binary_message(bytes)
        }
    }

    fn handle_binary_message(&self, bytes: Vec<u8>) {
        let bytes = Bytes::from(bytes);
        match WebScoketRawMessage::try_from(bytes) {
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

impl Future for WSHandlerFuture {
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
pub struct WSSender {
    ws_tx: MsgSender,
}

impl WSSender {
    pub fn send_msg<T: Into<WebScoketRawMessage>>(&self, msg: T) -> Result<(), WSError> {
        let msg = msg.into();
        let _ = self
            .ws_tx
            .unbounded_send(msg.into())
            .map_err(|e| WSError::internal().context(e))?;
        Ok(())
    }

    pub fn send_text(&self, source: &WSModule, text: &str) -> Result<(), WSError> {
        let msg = WebScoketRawMessage {
            module: source.clone(),
            data: text.as_bytes().to_vec(),
        };
        self.send_msg(msg)
    }

    pub fn send_binary(&self, source: &WSModule, bytes: Vec<u8>) -> Result<(), WSError> {
        let msg = WebScoketRawMessage {
            module: source.clone(),
            data: bytes,
        };
        self.send_msg(msg)
    }

    pub fn send_disconnect(&self, reason: &str) -> Result<(), WSError> {
        let frame = CloseFrame {
            code: CloseCode::Normal,
            reason: reason.to_owned().into(),
        };
        let msg = Message::Close(Some(frame));
        let _ = self
            .ws_tx
            .unbounded_send(msg)
            .map_err(|e| WSError::internal().context(e))?;
        Ok(())
    }
}

struct WSConnectAction {
    addr: String,
    handlers: Handlers,
}

impl Action for WSConnectAction {
    type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send + Sync>>;
    type Item = WSConnectResult;
    type Error = WSError;

    fn run(&mut self) -> Self::Future {
        let addr = self.addr.clone();
        let handlers = self.handlers.clone();
        Box::pin(WSConnectActionFut::new(addr, handlers))
    }
}

struct WSConnectResult {
    stream: WSStream,
    handlers_fut: WSHandlerFuture,
    sender: WSSender,
}

#[pin_project]
struct WSConnectActionFut {
    addr: String,
    #[pin]
    conn: WSConnectionFuture,
    handlers_fut: Option<WSHandlerFuture>,
    sender: Option<WSSender>,
}

impl WSConnectActionFut {
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
        let sender = WSSender { ws_tx };
        let handlers_fut = WSHandlerFuture::new(handlers, msg_rx);
        let conn = WSConnectionFuture::new(msg_tx, ws_rx, addr.clone());
        Self {
            addr,
            conn,
            handlers_fut: Some(handlers_fut),
            sender: Some(sender),
        }
    }
}

impl Future for WSConnectActionFut {
    type Output = Result<WSConnectResult, WSError>;
    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let mut this = self.project();
        match ready!(this.conn.as_mut().poll(cx)) {
            Ok(stream) => {
                let handlers_fut = this.handlers_fut.take().expect("Only take once");
                let sender = this.sender.take().expect("Only take once");
                Poll::Ready(Ok(WSConnectResult {
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
pub enum WSConnectState {
    Init,
    Connecting,
    Connected,
    Disconnected,
}

impl std::fmt::Display for WSConnectState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            WSConnectState::Init => f.write_str("Init"),
            WSConnectState::Connected => f.write_str("Connecting"),
            WSConnectState::Connecting => f.write_str("Connected"),
            WSConnectState::Disconnected => f.write_str("Disconnected"),
        }
    }
}

impl std::fmt::Debug for WSConnectState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str(&format!("{}", self)) }
}

struct WSSenderController {
    state: WSConnectState,
    state_notify: Arc<broadcast::Sender<WSConnectState>>,
    sender: Option<Arc<WSSender>>,
}

impl WSSenderController {
    fn set_sender(&mut self, sender: WSSender) { self.sender = Some(Arc::new(sender)); }

    fn set_state(&mut self, state: WSConnectState) {
        if state != WSConnectState::Connected {
            self.sender = None;
        }

        self.state = state;
        let _ = self.state_notify.send(self.state.clone());
    }

    fn set_error(&mut self, error: WSError) {
        log::error!("{:?}", error);
        self.set_state(WSConnectState::Disconnected);
    }

    fn sender(&self) -> Option<Arc<WSSender>> { self.sender.clone() }

    fn is_connecting(&self) -> bool { self.state == WSConnectState::Connecting }

    #[allow(dead_code)]
    fn is_connected(&self) -> bool { self.state == WSConnectState::Connected }
}

impl std::default::Default for WSSenderController {
    fn default() -> Self {
        let (state_notify, _) = broadcast::channel(16);
        WSSenderController {
            state: WSConnectState::Init,
            state_notify: Arc::new(state_notify),
            sender: None,
        }
    }
}
