use crate::errors::WsError;
use flowy_net::{errors::ServerError, response::FlowyResponse};
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{future::BoxFuture, ready, Stream};
use futures_util::{pin_mut, FutureExt, StreamExt};
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
    tungstenite::{handshake::client::Response, http::StatusCode, Error, Message},
    MaybeTlsStream,
    WebSocketStream,
};

pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;
pub trait WsMessageHandler: Sync + Send + 'static {
    fn can_handle(&self) -> bool;
    fn receive_message(&self, msg: &Message);
    fn send_message(&self, sender: Arc<WsSender>);
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

    #[allow(dead_code)]
    pub async fn connect(&mut self, addr: String) -> Result<(), ServerError> {
        let (conn, handlers) = self.make_connect(addr);
        let _ = conn.await?;
        let _ = tokio::spawn(handlers);
        Ok(())
    }

    pub fn make_connect(&mut self, addr: String) -> (WsConnection, WsHandlers) {
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
        let sender = Arc::new(WsSender::new(ws_tx));
        let handlers = self.handlers.clone();
        self.sender = Some(sender.clone());
        (WsConnection::new(msg_tx, ws_rx, addr), WsHandlers::new(handlers, msg_rx))
    }

    pub fn send_message(&self, msg: Message) -> Result<(), WsError> {
        match &self.sender {
            None => panic!(),
            Some(conn) => conn.send(msg),
        }
    }
}

#[pin_project]
pub struct WsHandlers {
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
                    handler.receive_message(&message);
                }),
            }
        }
    }
}

#[pin_project]
pub struct WsConnection {
    msg_tx: Option<MsgSender>,
    ws_rx: Option<MsgReceiver>,
    #[pin]
    fut: BoxFuture<'static, Result<(WebSocketStream<MaybeTlsStream<TcpStream>>, Response), Error>>,
}

impl WsConnection {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, addr: String) -> Self {
        WsConnection {
            msg_tx: Some(msg_tx),
            ws_rx: Some(ws_rx),
            fut: Box::pin(async move { connect_async(&addr).await }),
        }
    }
}

impl Future for WsConnection {
    type Output = Result<(), ServerError>;
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
                    let mut ws_stream = WsStream {
                        msg_tx: self.msg_tx.take(),
                        ws_rx: self.ws_rx.take(),
                        stream: Some(stream),
                    };
                    match Pin::new(&mut ws_stream).poll(cx) {
                        Poll::Ready(_) => Poll::Ready(Ok(())),
                        Poll::Pending => Poll::Pending,
                    }
                },
                Err(error) => Poll::Ready(Err(error_to_flowy_response(error))),
            };
        }
    }
}

fn error_to_flowy_response(error: tokio_tungstenite::tungstenite::Error) -> ServerError {
    let error = match error {
        Error::Http(response) => {
            if response.status() == StatusCode::UNAUTHORIZED {
                ServerError::unauthorized()
            } else {
                ServerError::internal().context(response)
            }
        },
        _ => ServerError::internal().context(error),
    };

    error
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
        log::trace!("🐴 ws start poll stream");
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
