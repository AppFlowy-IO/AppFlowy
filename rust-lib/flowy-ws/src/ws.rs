use crate::{
    connect::{WsConnectionFuture, WsStream},
    errors::WsError,
    WsMessage,
    WsModule,
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_infra::retry::{Action, ExponentialBackoff, FixedInterval, Retry};
use flowy_net::errors::ServerError;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{ready, Stream};
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

impl std::fmt::Display for WsState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            WsState::Init => f.write_str("Init"),
            WsState::Connected(_) => f.write_str("Connected"),
            WsState::Disconnected(_) => f.write_str("Disconnected"),
        }
    }
}

impl std::fmt::Debug for WsState {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str(&format!("{}", self)) }
}

pub struct WsController {
    handlers: Handlers,
    state_notify: Arc<broadcast::Sender<WsState>>,
    sender: Arc<RwLock<Option<Arc<WsSender>>>>,
    addr: Arc<RwLock<Option<String>>>,
}

impl WsController {
    pub fn new() -> Self {
        let (state_notify, _) = broadcast::channel(16);
        let controller = Self {
            handlers: DashMap::new(),
            sender: Arc::new(RwLock::new(None)),
            state_notify: Arc::new(state_notify),
            addr: Arc::new(RwLock::new(None)),
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

    pub async fn start_connect(&self, addr: String) -> Result<(), ServerError> {
        *self.addr.write() = Some(addr.clone());

        let strategy = ExponentialBackoff::from_millis(100).take(5);
        self.connect(addr, strategy).await
    }

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
        let sender_holder = self.sender.clone();
        let state_notify = self.state_notify.clone();

        tokio::spawn(async move {
            match retry.await {
                Ok(result) => {
                    let WsConnectResult {
                        stream,
                        handlers_fut,
                        sender,
                    } = result;
                    let sender = Arc::new(sender);
                    *sender_holder.write() = Some(sender.clone());

                    let _ = state_notify.send(WsState::Connected(sender));
                    let _ = ret.send(Ok(()));
                    spawn_stream_and_handlers(stream, handlers_fut, state_notify).await;
                },
                Err(e) => {
                    //
                    let _ = state_notify.send(WsState::Disconnected(e.clone()));
                    let _ = ret.send(Err(ServerError::internal().context(e)));
                },
            }
        });

        rx.await?
    }

    pub async fn retry(&self) -> Result<(), ServerError> {
        let addr = self
            .addr
            .read()
            .as_ref()
            .expect("must call start_connect first")
            .clone();
        let strategy = FixedInterval::from_millis(5000);
        self.connect(addr, strategy).await
    }

    pub fn state_subscribe(&self) -> broadcast::Receiver<WsState> { self.state_notify.subscribe() }

    pub fn sender(&self) -> Result<Arc<WsSender>, WsError> {
        match &*self.sender.read() {
            None => Err(WsError::internal().context("WsSender is not initialized, should call connect first")),
            Some(sender) => Ok(sender.clone()),
        }
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
                    log::error!("websocket error: {:?}", e);
                    let _ = state_notify.send(WsState::Disconnected(e)).unwrap();
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

struct WsConnectAction {
    addr: String,
    handlers: Handlers,
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
            Err(e) => Poll::Ready(Err(WsError::internal().context(e))),
        }
    }
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
