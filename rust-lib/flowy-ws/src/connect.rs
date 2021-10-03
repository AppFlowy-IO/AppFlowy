use crate::{errors::WsError, MsgReceiver, MsgSender};
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
    MaybeTlsStream,
    WebSocketStream,
};

#[pin_project]
pub struct WsConnectionFuture {
    msg_tx: Option<MsgSender>,
    ws_rx: Option<MsgReceiver>,
    #[pin]
    fut: Pin<
        Box<dyn Future<Output = Result<(WebSocketStream<MaybeTlsStream<TcpStream>>, Response), Error>> + Send + Sync>,
    >,
}

impl WsConnectionFuture {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, addr: String) -> Self {
        WsConnectionFuture {
            msg_tx: Some(msg_tx),
            ws_rx: Some(ws_rx),
            fut: Box::pin(async move { connect_async(&addr).await }),
        }
    }
}

impl Future for WsConnectionFuture {
    type Output = Result<WsStream, WsError>;
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
                    let (msg_tx, ws_rx) = (
                        self.msg_tx.take().expect("WsConnection should be call once "),
                        self.ws_rx.take().expect("WsConnection should be call once "),
                    );
                    Poll::Ready(Ok(WsStream::new(msg_tx, ws_rx, stream)))
                },
                Err(error) => {
                    log::debug!("🐴 ws connect failed: {:?}", error);
                    Poll::Ready(Err(error.into()))
                },
            };
        }
    }
}

type Fut = BoxFuture<'static, Result<(), WsError>>;
#[pin_project]
pub struct WsStream {
    #[allow(dead_code)]
    msg_tx: MsgSender,
    #[pin]
    inner: Option<(Fut, Fut)>,
}

impl WsStream {
    pub fn new(msg_tx: MsgSender, ws_rx: MsgReceiver, stream: WebSocketStream<MaybeTlsStream<TcpStream>>) -> Self {
        let (ws_write, ws_read) = stream.split();
        Self {
            msg_tx: msg_tx.clone(),
            inner: Some((
                Box::pin(async move {
                    let _ = ws_read
                        .for_each(|message| async { post_message(msg_tx.clone(), message) })
                        .await;
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
        Err(e) => {
            log::error!("ws read error: {:?}", e)
        },
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
