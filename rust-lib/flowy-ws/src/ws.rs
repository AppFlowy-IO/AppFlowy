use crate::errors::WsError;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{ready, Stream};
use futures_util::StreamExt;
use pin_project::pin_project;
use std::{
    future::Future,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};
use tokio::net::TcpStream;
use tokio_tungstenite::{connect_async, tungstenite::Message, MaybeTlsStream, WebSocketStream};
pub type MsgReceiver = UnboundedReceiver<Message>;
pub type MsgSender = UnboundedSender<Message>;

pub trait WsMessageHandler: Sync + Send + 'static {
    fn handler_message(&self, msg: &Message);
}

pub struct WsController {
    connection: Option<Arc<WsConnect>>,
    handlers: Vec<Arc<dyn WsMessageHandler>>,
}

impl WsController {
    pub fn new() -> Self {
        Self {
            connection: None,
            handlers: vec![],
        }
    }

    pub fn add_handlers(&mut self, handler: Arc<dyn WsMessageHandler>) { self.handlers.push(handler); }

    pub async fn connect(&mut self, addr: &str) -> Result<(), WsError> {
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
        let mut ws_raw = WsRaw::new(msg_tx, ws_rx);
        let connection = Arc::new(WsConnect::new(ws_tx));

        self.connection = Some(connection.clone());

        let start_connect = { ws_raw.connect(&addr) };
        let spawn_handlers = SpawnHandlers::new(self.handlers.clone(), msg_rx);
        // let spawn_handlers = {
        //     msg_rx.for_each(|message| async move {
        //         let handlers: Arc<Vec<Arc<dyn WsMessageHandler>>> = Arc::new(vec![]);
        //         handlers.iter().for_each(|handler| {
        //             handler.handler_message(&message);
        //         });
        //     })
        // };
        tokio::select! {
            _ = spawn_handlers => {
                log::debug!("Websocket read completed")
            }
            _ = start_connect => {
                log::debug!("Connection completed")
            }
        };

        Ok(())
    }

    pub fn send_message(&self, msg: Message) -> Result<(), WsError> {
        match &self.connection {
            None => panic!(),
            Some(conn) => conn.send(msg),
        }
    }
}

#[pin_project]
struct SpawnHandlers {
    #[pin]
    msg_rx: MsgReceiver,
    handlers: Vec<Arc<dyn WsMessageHandler>>,
}

impl SpawnHandlers {
    fn new(handlers: Vec<Arc<dyn WsMessageHandler>>, msg_rx: MsgReceiver) -> Self { Self { msg_rx, handlers } }
}

impl Future for SpawnHandlers {
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

pub struct WsConnect {
    ws_tx: MsgSender,
}

impl WsConnect {
    pub fn new(ws_tx: MsgSender) -> Self { Self { ws_tx } }
    pub fn send(&self, msg: Message) -> Result<(), WsError> {
        let _ = self.ws_tx.unbounded_send(msg)?;
        Ok(())
    }
}

pub struct WsRaw {
    msg_tx: Option<MsgSender>,
    ws_rx: Option<MsgReceiver>,
}

impl WsRaw {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver) -> Self {
        WsRaw {
            msg_tx: Some(msg_tx),
            ws_rx: Some(ws_rx),
        }
    }

    pub async fn connect(&mut self, addr: &str) -> Result<(), WsError> {
        let url = url::Url::parse(addr)?;
        match connect_async(url).await {
            Ok((stream, _)) => self.bind_stream(stream).await,
            Err(e) => Err(WsError::internal().context(e)),
        }
    }

    async fn bind_stream(&mut self, stream: WebSocketStream<MaybeTlsStream<TcpStream>>) -> Result<(), WsError> {
        let (ws_write, ws_read) = stream.split();
        let (tx, rx) = self.take_mpsc();
        let to_ws = rx.map(Ok).forward(ws_write);
        let from_ws = {
            ws_read.for_each(|message| async {
                match message {
                    Ok(message) => {
                        match tx.unbounded_send(message) {
                            Ok(_) => {},
                            Err(e) => log::error!("tx send error: {:?}", e),
                        };
                    },
                    Err(e) => log::error!("ws read error: {:?}", e),
                }
            })
        };
        tokio::select! {
            _ = to_ws => {
                log::debug!("ws write completed")
            }
            _ = from_ws => {
                log::debug!("ws read completed")
            }
        };
        Ok(())
    }

    fn take_mpsc(&mut self) -> (MsgSender, MsgReceiver) { (self.msg_tx.take().unwrap(), self.ws_rx.take().unwrap()) }
}
