use crate::{errors::WsError, MsgReceiver, MsgSender, WsMessage};
use flowy_net::errors::ServerError;
use futures_channel::mpsc::{UnboundedReceiver, UnboundedSender};
use futures_core::{future::BoxFuture, ready, Stream};
use futures_util::{
    future,
    future::{Either, Select},
    pin_mut,
    FutureExt,
    StreamExt,
};
use pin_project::pin_project;
use std::{
    collections::HashMap,
    future::Future,
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};
use tokio::{net::TcpStream, task::JoinHandle};
use tokio_tungstenite::{
    connect_async,
    tungstenite::{handshake::client::Response, http::StatusCode, Error, Message},
    MaybeTlsStream,
    WebSocketStream,
};

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
    type Output = Result<WsStream, ServerError>;
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
                    let (msg_tx, ws_rx) = (self.msg_tx.take().unwrap(), self.ws_rx.take().unwrap());
                    Poll::Ready(Ok(WsStream::new(msg_tx, ws_rx, stream)))
                },
                Err(error) => Poll::Ready(Err(error_to_flowy_response(error))),
            };
        }
    }
}

#[pin_project]
pub struct WsStream {
    msg_tx: MsgSender,
    #[pin]
    fut: Option<(BoxFuture<'static, ()>, BoxFuture<'static, ()>)>,
}

impl WsStream {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, stream: WebSocketStream<MaybeTlsStream<TcpStream>>) -> Self {
        let (ws_write, ws_read) = stream.split();
        let to_ws = ws_rx.map(Ok).forward(ws_write);
        let from_ws = ws_read.for_each(|message| async {
            // handle_new_message(msg_tx.clone(), message)
        });
        // pin_mut!(to_ws, from_ws);
        Self {
            msg_tx,
            fut: Some((
                Box::pin(async move {
                    let _ = from_ws.await;
                }),
                Box::pin(async move {
                    let _ = to_ws.await;
                }),
            )),
        }
    }
}

impl Future for WsStream {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let (mut a, mut b) = self.fut.take().unwrap();
        match a.poll_unpin(cx) {
            Poll::Ready(x) => Poll::Ready(()),
            Poll::Pending => match b.poll_unpin(cx) {
                Poll::Ready(x) => Poll::Ready(()),
                Poll::Pending => {
                    // self.fut = Some((a, b));
                    Poll::Pending
                },
            },
        }
    }
}

// pub struct WsStream {
//     msg_tx: Option<MsgSender>,
//     ws_rx: Option<MsgReceiver>,
//     stream: Option<WebSocketStream<MaybeTlsStream<TcpStream>>>,
// }
//
// impl WsStream {
//     pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, stream:
// WebSocketStream<MaybeTlsStream<TcpStream>>) -> Self {         Self {
//             msg_tx: Some(msg_tx),
//             ws_rx: Some(ws_rx),
//             stream: Some(stream),
//         }
//     }
//
//     pub fn start(mut self) -> JoinHandle<()> {
//         let (msg_tx, ws_rx) = (self.msg_tx.take().unwrap(),
// self.ws_rx.take().unwrap());         let (ws_write, ws_read) =
// self.stream.take().unwrap().split();         tokio::spawn(async move {
//             let to_ws = ws_rx.map(Ok).forward(ws_write);
//             let from_ws = ws_read.for_each(|message| async {
// handle_new_message(msg_tx.clone(), message) });             pin_mut!(to_ws,
// from_ws);
//
//             match future::select(to_ws, from_ws).await {
//                 Either::Left(_l) => {
//                     log::info!("ws left");
//                 },
//                 Either::Right(_r) => {
//                     log::info!("ws right");
//                 },
//             }
//         })
//     }
// }
//
// impl Future for WsStream {
//     type Output = ();
//     fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) ->
// Poll<Self::Output> {         let (msg_tx, ws_rx) =
// (self.msg_tx.take().unwrap(), self.ws_rx.take().unwrap());         let
// (ws_write, ws_read) = self.stream.take().unwrap().split();         let to_ws
// = ws_rx.map(Ok).forward(ws_write);         let from_ws =
// ws_read.for_each(|message| async { handle_new_message(msg_tx.clone(),
// message) });         pin_mut!(to_ws, from_ws);
//
//         loop {
//             match ready!(Pin::new(&mut future::select(to_ws,
// from_ws)).poll(cx)) {                 Either::Left(a) => {
//                     //
//                     return Poll::Ready(());
//                 },
//                 Either::Right(b) => {
//                     //
//                     return Poll::Ready(());
//                 },
//             }
//         }
//     }
// }

fn handle_new_message(tx: MsgSender, message: Result<Message, Error>) {
    match message {
        Ok(Message::Binary(bytes)) => match tx.unbounded_send(Message::Binary(bytes)) {
            Ok(_) => {},
            Err(e) => log::error!("tx send error: {:?}", e),
        },
        Ok(_) => {},
        Err(e) => log::error!("ws read error: {:?}", e),
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
