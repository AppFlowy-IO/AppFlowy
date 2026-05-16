use futures_core::Stream;
use std::pin::Pin;
use std::task::{Context, Poll};
use tokio::sync::mpsc;
use tokio::sync::mpsc::{Receiver, Sender};

struct BoundedStream<T> {
  recv: Receiver<T>,
}
impl<T> Stream for BoundedStream<T> {
  type Item = T;
  fn poll_next(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<T>> {
    Pin::into_inner(self).recv.poll_recv(cx)
  }
}

pub fn mpsc_channel_stream<T: Unpin>(size: usize) -> (Sender<T>, impl Stream<Item = T>) {
  let (tx, rx) = mpsc::channel(size);
  let stream = BoundedStream { recv: rx };
  (tx, stream)
}
