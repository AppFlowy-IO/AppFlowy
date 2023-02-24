use std::{
  future::Future,
  pin::Pin,
  task::{Context, Poll},
};

pub struct Ready<T> {
  val: Option<T>,
}

impl<T> Ready<T> {
  #[inline]
  pub fn into_inner(mut self) -> T {
    self.val.take().unwrap()
  }
}

impl<T> Unpin for Ready<T> {}

impl<T> Future for Ready<T> {
  type Output = T;

  #[inline]
  fn poll(mut self: Pin<&mut Self>, _cx: &mut Context<'_>) -> Poll<T> {
    let val = self.val.take().expect("Ready polled after completion");
    Poll::Ready(val)
  }
}

pub fn ready<T>(val: T) -> Ready<T> {
  Ready { val: Some(val) }
}
