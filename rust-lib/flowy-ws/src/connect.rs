use crate::{errors::WsError, MsgReceiver, MsgSender};
use flowy_net::errors::ServerError;
use futures_core::{future::BoxFuture, ready};
use futures_util::{FutureExt, StreamExt, TryStreamExt};
use pin_project::pin_project;
use std::{
    fmt,
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
                    log::debug!("🐴 ws connect success: {:?}", error);
                    let (msg_tx, ws_rx) = (self.msg_tx.take().unwrap(), self.ws_rx.take().unwrap());
                    Poll::Ready(Ok(WsStream::new(msg_tx, ws_rx, stream)))
                },
                Err(error) => {
                    log::debug!("🐴 ws connect failed: {:?}", error);
                    Poll::Ready(Err(error_to_flowy_response(error)))
                },
            };
        }
    }
}

type Fut = BoxFuture<'static, Result<(), WsError>>;
#[pin_project]
pub struct WsStream {
    #[pin]
    inner: Option<(Fut, Fut)>,
}

impl WsStream {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, stream: WebSocketStream<MaybeTlsStream<TcpStream>>) -> Self {
        let (ws_write, ws_read) = stream.split();
        Self {
            inner: Some((
                Box::pin(async move {
                    let _ = ws_read.for_each(|message| async { post_message(msg_tx.clone(), message) }).await;
                    Ok(())
                }),
                Box::pin(async move {
                    let _ = ws_rx.map(Ok).forward(ws_write).await?;
                    Ok(())
                }),
            )),
        }
    }
}

impl fmt::Debug for WsStream {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { f.debug_struct("WsStream").finish() }
}

impl Future for WsStream {
    type Output = Result<(), WsError>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let (mut left, mut right) = self.inner.take().unwrap();
        match left.poll_unpin(cx) {
            Poll::Ready(l) => Poll::Ready(l),
            Poll::Pending => {
                //
                match right.poll_unpin(cx) {
                    Poll::Ready(r) => Poll::Ready(r),
                    Poll::Pending => {
                        self.inner = Some((left, right));
                        Poll::Pending
                    },
                }
            },
        }
    }
}

fn post_message(tx: MsgSender, message: Result<Message, Error>) {
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
