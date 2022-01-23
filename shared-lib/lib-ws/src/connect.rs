#![allow(clippy::all)]
use crate::{
    errors::{internal_error, WSError},
    MsgReceiver, MsgSender,
};
use futures_core::{future::BoxFuture, ready};
use futures_util::{FutureExt, StreamExt};
use pin_project::pin_project;
use std::{
    fmt,
    future::Future,
    pin::Pin,
    task::{Context, Poll},
};
use tokio::net::TcpStream;
use tokio_tungstenite::{
    connect_async,
    tungstenite::{handshake::client::Response, Error, Message},
    MaybeTlsStream, WebSocketStream,
};

type WsConnectResult = Result<(WebSocketStream<MaybeTlsStream<TcpStream>>, Response), Error>;

#[pin_project]
pub struct WSConnectionFuture {
    msg_tx: Option<MsgSender>,
    ws_rx: Option<MsgReceiver>,
    #[pin]
    fut: Pin<Box<dyn Future<Output = WsConnectResult> + Send + Sync>>,
}

impl WSConnectionFuture {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, addr: String) -> Self {
        WSConnectionFuture {
            msg_tx: Some(msg_tx),
            ws_rx: Some(ws_rx),
            fut: Box::pin(async move { connect_async(&addr).await }),
        }
    }
}

impl Future for WSConnectionFuture {
    type Output = Result<WSStream, WSError>;
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
                    tracing::debug!("🐴 ws connect success");
                    let (msg_tx, ws_rx) = (
                        self.msg_tx.take().expect("WsConnection should be call once "),
                        self.ws_rx.take().expect("WsConnection should be call once "),
                    );
                    Poll::Ready(Ok(WSStream::new(msg_tx, ws_rx, stream)))
                }
                Err(error) => {
                    tracing::debug!("🐴 ws connect failed: {:?}", error);
                    Poll::Ready(Err(error.into()))
                }
            };
        }
    }
}

type Fut = BoxFuture<'static, Result<(), WSError>>;
#[pin_project]
pub struct WSStream {
    #[allow(dead_code)]
    msg_tx: MsgSender,
    #[pin]
    inner: Option<(Fut, Fut)>,
}

impl WSStream {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, stream: WebSocketStream<MaybeTlsStream<TcpStream>>) -> Self {
        let (ws_write, ws_read) = stream.split();
        Self {
            msg_tx: msg_tx.clone(),
            inner: Some((
                Box::pin(async move {
                    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel();
                    let read = async {
                        ws_read
                            .for_each(|message| async {
                                match tx.send(send_message(msg_tx.clone(), message)) {
                                    Ok(_) => {}
                                    Err(e) => log::error!("WsStream tx closed unexpectedly: {} ", e),
                                }
                            })
                            .await;
                        Ok(())
                    };

                    let read_ret = async {
                        loop {
                            match rx.recv().await {
                                None => {
                                    return Err(WSError::internal().context("WsStream rx closed unexpectedly"));
                                }
                                Some(result) => {
                                    if result.is_err() {
                                        return result;
                                    }
                                }
                            }
                        }
                    };
                    futures::pin_mut!(read);
                    futures::pin_mut!(read_ret);
                    return tokio::select! {
                        result = read => result,
                        result = read_ret => result,
                    };
                }),
                Box::pin(async move {
                    let result = ws_rx.map(Ok).forward(ws_write).await.map_err(internal_error);
                    result
                }),
            )),
        }
    }
}

impl fmt::Debug for WSStream {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("WSStream").finish()
    }
}

impl Future for WSStream {
    type Output = Result<(), WSError>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let (mut ws_read, mut ws_write) = self.inner.take().unwrap();
        match ws_read.poll_unpin(cx) {
            Poll::Ready(l) => Poll::Ready(l),
            Poll::Pending => {
                //
                match ws_write.poll_unpin(cx) {
                    Poll::Ready(r) => Poll::Ready(r),
                    Poll::Pending => {
                        self.inner = Some((ws_read, ws_write));
                        Poll::Pending
                    }
                }
            }
        }
    }
}

fn send_message(msg_tx: MsgSender, message: Result<Message, Error>) -> Result<(), WSError> {
    match message {
        Ok(Message::Binary(bytes)) => msg_tx.unbounded_send(Message::Binary(bytes)).map_err(internal_error),
        Ok(_) => Ok(()),
        Err(e) => Err(WSError::internal().context(e)),
    }
}
#[allow(dead_code)]
pub struct Retry<F> {
    f: F,
    #[allow(dead_code)]
    retry_time: usize,
    addr: String,
}

impl<F> Retry<F>
where
    F: Fn(&str),
{
    #[allow(dead_code)]
    pub fn new(addr: &str, f: F) -> Self {
        Self {
            f,
            retry_time: 3,
            addr: addr.to_owned(),
        }
    }
}

impl<F> Future for Retry<F>
where
    F: Fn(&str),
{
    type Output = ();

    fn poll(self: Pin<&mut Self>, _cx: &mut Context<'_>) -> Poll<Self::Output> {
        (self.f)(&self.addr);

        Poll::Ready(())
    }
}
