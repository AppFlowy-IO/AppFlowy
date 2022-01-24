#![allow(clippy::type_complexity)]
use crate::{
    connect::{WSConnectionFuture, WSStream},
    errors::WSError,
    WSChannel, WebSocketRawMessage,
};
use backend_service::errors::ServerError;
use bytes::Bytes;
use dashmap::DashMap;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{ready, Stream};
use lib_infra::retry::{Action, FixedInterval, Retry};
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
use tokio::sync::{broadcast, oneshot, RwLock};
use tokio_tungstenite::tungstenite::{
    protocol::{frame::coding::CloseCode, CloseFrame},
    Message,
};

pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;
type Handlers = DashMap<WSChannel, Arc<dyn WSMessageReceiver>>;

pub trait WSMessageReceiver: Sync + Send + 'static {
    fn source(&self) -> WSChannel;
    fn receive_message(&self, msg: WebSocketRawMessage);
}

pub struct WSController {
    handlers: Handlers,
    addr: Arc<RwLock<Option<String>>>,
    sender: Arc<RwLock<Option<Arc<WSSender>>>>,
    conn_state_notify: Arc<RwLock<WSConnectStateNotifier>>,
}

impl std::fmt::Display for WSController {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str("WebSocket")
    }
}

impl std::default::Default for WSController {
    fn default() -> Self {
        Self {
            handlers: DashMap::new(),
            addr: Arc::new(RwLock::new(None)),
            sender: Arc::new(RwLock::new(None)),
            conn_state_notify: Arc::new(RwLock::new(WSConnectStateNotifier::default())),
        }
    }
}

impl WSController {
    pub fn new() -> Self {
        WSController::default()
    }

    pub fn add_ws_message_receiver(&self, handler: Arc<dyn WSMessageReceiver>) -> Result<(), WSError> {
        let source = handler.source();
        if self.handlers.contains_key(&source) {
            log::error!("{:?} is already registered", source);
        }
        self.handlers.insert(source, handler);
        Ok(())
    }

    pub async fn start(&self, addr: String) -> Result<(), ServerError> {
        *self.addr.write().await = Some(addr.clone());
        let strategy = FixedInterval::from_millis(5000).take(3);
        self.connect(addr, strategy).await
    }

    pub async fn stop(&self) {
        if self.conn_state_notify.read().await.conn_state.is_connected() {
            tracing::trace!("[{}] stop", self);
            self.conn_state_notify
                .write()
                .await
                .update_state(WSConnectState::Disconnected);
        }
    }

    async fn connect<T, I>(&self, addr: String, strategy: T) -> Result<(), ServerError>
    where
        T: IntoIterator<IntoIter = I, Item = Duration>,
        I: Iterator<Item = Duration> + Send + 'static,
    {
        let mut conn_state_notify = self.conn_state_notify.write().await;
        let conn_state = conn_state_notify.conn_state.clone();
        if conn_state.is_connected() || conn_state.is_connecting() {
            return Ok(());
        }

        let (ret, rx) = oneshot::channel::<Result<(), ServerError>>();
        *self.addr.write().await = Some(addr.clone());
        let action = WSConnectAction {
            addr,
            handlers: self.handlers.clone(),
        };
        let retry = Retry::spawn(strategy, action);
        conn_state_notify.update_state(WSConnectState::Connecting);
        drop(conn_state_notify);

        let cloned_conn_state = self.conn_state_notify.clone();
        let cloned_sender = self.sender.clone();
        tracing::trace!("[{}] start connecting", self);
        tokio::spawn(async move {
            match retry.await {
                Ok(result) => {
                    let WSConnectResult {
                        stream,
                        handlers_fut,
                        sender,
                    } = result;

                    cloned_conn_state.write().await.update_state(WSConnectState::Connected);
                    *cloned_sender.write().await = Some(Arc::new(sender));

                    let _ = ret.send(Ok(()));
                    spawn_stream_and_handlers(stream, handlers_fut).await;
                }
                Err(e) => {
                    cloned_conn_state
                        .write()
                        .await
                        .update_state(WSConnectState::Disconnected);
                    let _ = ret.send(Err(ServerError::internal().context(e)));
                }
            }
        });
        rx.await?
    }

    pub async fn retry(&self, count: usize) -> Result<(), ServerError> {
        if !self.conn_state_notify.read().await.conn_state.is_disconnected() {
            return Ok(());
        }

        tracing::trace!("[WebSocket]: retry connect...");
        let strategy = FixedInterval::from_millis(5000).take(count);
        let addr = self
            .addr
            .read()
            .await
            .as_ref()
            .expect("Retry web socket connection failed, should call start_connect first")
            .clone();

        self.connect(addr, strategy).await
    }

    pub async fn subscribe_state(&self) -> broadcast::Receiver<WSConnectState> {
        self.conn_state_notify.read().await.notify.subscribe()
    }

    pub async fn ws_message_sender(&self) -> Result<Option<Arc<WSSender>>, WSError> {
        let sender = self.sender.read().await.clone();
        match sender {
            None => match self.conn_state_notify.read().await.conn_state {
                WSConnectState::Disconnected => {
                    let msg = "WebSocket is disconnected";
                    Err(WSError::internal().context(msg))
                }
                _ => Ok(None),
            },
            Some(sender) => Ok(Some(sender)),
        }
    }
}

async fn spawn_stream_and_handlers(stream: WSStream, handlers: WSHandlerFuture) {
    tokio::select! {
        result = stream => {
            if let Err(e) = result {
                tracing::error!("WSStream error: {:?}", e);
            }
        },
        result = handlers => tracing::debug!("handlers completed {:?}", result),
    };
}

#[pin_project]
pub struct WSHandlerFuture {
    #[pin]
    msg_rx: MsgReceiver,
    handlers: Handlers,
}

impl WSHandlerFuture {
    fn new(handlers: Handlers, msg_rx: MsgReceiver) -> Self {
        Self { msg_rx, handlers }
    }

    fn handler_ws_message(&self, message: Message) {
        if let Message::Binary(bytes) = message {
            self.handle_binary_message(bytes)
        }
    }

    fn handle_binary_message(&self, bytes: Vec<u8>) {
        let bytes = Bytes::from(bytes);
        match WebSocketRawMessage::try_from(bytes) {
            Ok(message) => match self.handlers.get(&message.channel) {
                None => log::error!("Can't find any handler for message: {:?}", message),
                Some(handler) => handler.receive_message(message.clone()),
            },
            Err(e) => {
                log::error!("Deserialize binary ws message failed: {:?}", e);
            }
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
                }
                Some(message) => self.handler_ws_message(message),
            }
        }
    }
}

#[derive(Debug, Clone)]
pub struct WSSender(MsgSender);

impl WSSender {
    pub fn send_msg<T: Into<WebSocketRawMessage>>(&self, msg: T) -> Result<(), WSError> {
        let msg = msg.into();
        let _ = self
            .0
            .unbounded_send(msg.into())
            .map_err(|e| WSError::internal().context(e))?;
        Ok(())
    }

    pub fn send_text(&self, source: &WSChannel, text: &str) -> Result<(), WSError> {
        let msg = WebSocketRawMessage {
            channel: source.clone(),
            data: text.as_bytes().to_vec(),
        };
        self.send_msg(msg)
    }

    pub fn send_binary(&self, source: &WSChannel, bytes: Vec<u8>) -> Result<(), WSError> {
        let msg = WebSocketRawMessage {
            channel: source.clone(),
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
        let _ = self.0.unbounded_send(msg).map_err(|e| WSError::internal().context(e))?;
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
        let sender = WSSender(ws_tx);
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
            }
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

impl WSConnectState {
    fn is_connected(&self) -> bool {
        self == &WSConnectState::Connected
    }

    fn is_connecting(&self) -> bool {
        self == &WSConnectState::Connecting
    }

    fn is_disconnected(&self) -> bool {
        self == &WSConnectState::Disconnected || self == &WSConnectState::Init
    }
}

impl std::fmt::Display for WSConnectState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            WSConnectState::Init => f.write_str("Init"),
            WSConnectState::Connected => f.write_str("Connected"),
            WSConnectState::Connecting => f.write_str("Connecting"),
            WSConnectState::Disconnected => f.write_str("Disconnected"),
        }
    }
}

impl std::fmt::Debug for WSConnectState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.write_str(&format!("{}", self))
    }
}

struct WSConnectStateNotifier {
    conn_state: WSConnectState,
    notify: Arc<broadcast::Sender<WSConnectState>>,
}

impl std::default::Default for WSConnectStateNotifier {
    fn default() -> Self {
        let (state_notify, _) = broadcast::channel(16);
        Self {
            conn_state: WSConnectState::Init,
            notify: Arc::new(state_notify),
        }
    }
}

impl WSConnectStateNotifier {
    fn update_state(&mut self, new_state: WSConnectState) {
        if self.conn_state == new_state {
            return;
        }
        tracing::debug!(
            "WebSocket connect state did change: {} -> {}",
            self.conn_state,
            new_state
        );
        self.conn_state = new_state.clone();
        let _ = self.notify.send(new_state);
    }
}
