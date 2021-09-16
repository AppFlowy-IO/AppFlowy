use crate::errors::WsError;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{future::BoxFuture, ready, Stream};
use futures_util::{pin_mut, FutureExt, StreamExt};
use lazy_static::lazy_static;
use parking_lot::RwLock;
use pin_project::pin_project;
use std::{
    future::Future,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};
use tokio::net::TcpStream;
use tokio_tungstenite::{
    connect_async,
    tungstenite::{handshake::client::Response, Error, Message},
    MaybeTlsStream,
    WebSocketStream,
};
lazy_static! {
    pub static ref WS: RwLock<WsController> = RwLock::new(WsController::new());
}

pub fn start_ws_connection() { WS.write().connect(flowy_net::config::WS_ADDR.as_ref()); }

pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;
pub trait WsMessageHandler: Sync + Send + 'static {
    fn handler_message(&self, msg: &Message);
}

pub struct WsController {
    sender: Option<Arc<WsSender>>,
    handlers: Vec<Arc<dyn WsMessageHandler>>,
}

impl WsController {
    pub fn new() -> Self {
        let controller = Self {
            sender: None,
            handlers: vec![],
        };

        controller
    }

    pub fn add_handlers(&mut self, handler: Arc<dyn WsMessageHandler>) { self.handlers.push(handler); }

    pub fn connect(&mut self, addr: &str) {
        let (ws, handlers) = self.make_connect(&addr);
        let _ = tokio::spawn(ws);
        let _ = tokio::spawn(handlers);
    }

    fn make_connect(&mut self, addr: &str) -> (WsRaw, WsHandlers) {
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
        let addr = addr.to_string();
        let (msg_tx, msg_rx) = futures_channel::mpsc::unbounded();
        let (ws_tx, ws_rx) = futures_channel::mpsc::unbounded();
        let sender = Arc::new(WsSender::new(ws_tx));
        let handlers = self.handlers.clone();
        self.sender = Some(sender.clone());
        log::debug!("🐴ws prepare connection");

        (WsRaw::new(msg_tx, ws_rx, addr), WsHandlers::new(handlers, msg_rx))
    }

    pub fn send_message(&self, msg: Message) -> Result<(), WsError> {
        match &self.sender {
            None => panic!(),
            Some(conn) => conn.send(msg),
        }
    }
}

#[pin_project]
struct WsHandlers {
    #[pin]
    msg_rx: MsgReceiver,
    handlers: Vec<Arc<dyn WsMessageHandler>>,
}

impl WsHandlers {
    fn new(handlers: Vec<Arc<dyn WsMessageHandler>>, msg_rx: MsgReceiver) -> Self { Self { msg_rx, handlers } }
}

impl Future for WsHandlers {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(self.as_mut().project().msg_rx.poll_next(cx)) {
                None => return Poll::Ready(()),
                Some(message) => self.handlers.iter().for_each(|handler| {
                    handler.handler_message(&message);
                }),
            }
        }
    }
}

#[pin_project]
pub struct WsRaw {
    msg_tx: Option<MsgSender>,
    ws_rx: Option<MsgReceiver>,
    #[pin]
    fut: BoxFuture<'static, Result<(WebSocketStream<MaybeTlsStream<TcpStream>>, Response), Error>>,
}

impl WsRaw {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, addr: String) -> Self {
        WsRaw {
            msg_tx: Some(msg_tx),
            ws_rx: Some(ws_rx),
            fut: Box::pin(async move { connect_async(&addr).await }),
        }
    }
}

impl Future for WsRaw {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        // [[pin]]
        // poll async function.  The following methods not work.
        // 1.
        // let f = connect_async("");
        // pin_mut!(f);
        // ready!(Pin::new(&mut a).poll(cx))
        //
        // 2.ready!(Pin::new(&mut Box::pin(connect_async(""))).poll(cx))
        //
        // An async method calls poll multiple times and might return to the executor. A
        // single poll call can only return to the executor once and will get
        // resumed through another poll invocation. the connect_async call multiple time
        // from the beginning. So I use fut to hold the future and continue to
        // poll it. (Fix me if i was wrong)

        loop {
            return match ready!(self.as_mut().project().fut.poll(cx)) {
                Ok((stream, _)) => {
                    log::debug!("🐴 ws connect success");
                    let mut ws_stream = WsStream {
                        msg_tx: self.msg_tx.take(),
                        ws_rx: self.ws_rx.take(),
                        stream: Some(stream),
                    };
                    match Pin::new(&mut ws_stream).poll(cx) {
                        Poll::Ready(_a) => Poll::Ready(()),
                        Poll::Pending => Poll::Pending,
                    }
                },
                Err(e) => {
                    log::error!("🐴 ws connect failed: {:?}", e);
                    Poll::Ready(())
                },
            };
        }
    }
}

#[pin_project]
struct WsConn {
    #[pin]
    fut: BoxFuture<'static, Result<(WebSocketStream<MaybeTlsStream<TcpStream>>, Response), Error>>,
}

impl WsConn {
    fn new(addr: String) -> Self {
        Self {
            fut: Box::pin(async move { connect_async(&addr).await }),
        }
    }
}

impl Future for WsConn {
    type Output = Result<(WebSocketStream<MaybeTlsStream<TcpStream>>, Response), Error>;
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            return match ready!(self.as_mut().project().fut.poll(cx)) {
                Ok(o) => Poll::Ready(Ok(o)),
                Err(e) => Poll::Ready(Err(e)),
            };
        }
    }
}

struct WsStream {
    msg_tx: Option<MsgSender>,
    ws_rx: Option<MsgReceiver>,
    stream: Option<WebSocketStream<MaybeTlsStream<TcpStream>>>,
}

impl Future for WsStream {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let (tx, rx) = (self.msg_tx.take().unwrap(), self.ws_rx.take().unwrap());
        let (ws_write, ws_read) = self.stream.take().unwrap().split();
        let to_ws = rx.map(Ok).forward(ws_write);
        let from_ws = ws_read.for_each(|message| async {
            match message {
                Ok(message) => {
                    match tx.unbounded_send(message) {
                        Ok(_) => {},
                        Err(e) => log::error!("tx send error: {:?}", e),
                    };
                },
                Err(e) => log::error!("ws read error: {:?}", e),
            }
        });

        pin_mut!(to_ws, from_ws);
        log::debug!("🐴 ws start poll stream");
        match to_ws.poll_unpin(cx) {
            Poll::Ready(_) => Poll::Ready(()),
            Poll::Pending => match from_ws.poll_unpin(cx) {
                Poll::Ready(_) => Poll::Ready(()),
                Poll::Pending => Poll::Pending,
            },
        }
    }
}

pub struct WsSender {
    ws_tx: MsgSender,
}

impl WsSender {
    pub fn new(ws_tx: MsgSender) -> Self { Self { ws_tx } }

    pub fn send(&self, msg: Message) -> Result<(), WsError> {
        let _ = self.ws_tx.unbounded_send(msg)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::WsController;
    use futures_util::{pin_mut, StreamExt};
    use tokio_tungstenite::connect_async;

    #[tokio::test]
    async fn connect() {
        let mut controller = WsController::new();
        let addr = format!("{}/123", flowy_net::config::WS_ADDR.as_str());
        let (a, b) = controller.make_connect(&addr);
        tokio::select! {
            _ = a => println!("write completed"),
            _ = b => println!("read completed"),
        };
    }

    #[tokio::test]
    async fn connect_raw() {
        let _controller = WsController::new();
        let addr = format!("{}/123", flowy_net::config::WS_ADDR.as_str());
        let (tx, rx) = futures_channel::mpsc::unbounded();
        let (ws_write, ws_read) = connect_async(&addr).await.unwrap().0.split();
        let to_ws = rx.map(Ok).forward(ws_write);
        let from_ws = ws_read.for_each(|message| async {
            tx.unbounded_send(message.unwrap()).unwrap();
        });

        pin_mut!(to_ws, from_ws);
        tokio::select! {
            _ = to_ws => {
                log::debug!("ws write completed")
            }
            _ = from_ws => {
                log::debug!("ws read completed")
            }
        };
    }
}
