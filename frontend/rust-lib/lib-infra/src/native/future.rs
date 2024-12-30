use futures_core::future::BoxFuture;
use futures_core::ready;
use pin_project::pin_project;
use std::{
  future::Future,
  pin::Pin,
  task::{Context, Poll},
};

pub fn to_fut<T, O>(f: T) -> Fut<O>
where
  T: Future<Output = O> + Send + Sync + 'static,
{
  Fut { fut: Box::pin(f) }
}

#[pin_project]
pub struct Fut<T> {
  #[pin]
  pub fut: Pin<Box<dyn Future<Output = T> + Sync + Send>>,
}

impl<T> Future for Fut<T>
where
  T: Send + Sync,
{
  type Output = T;

  fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    let this = self.as_mut().project();
    Poll::Ready(ready!(this.fut.poll(cx)))
  }
}

pub type BoxResultFuture<'a, T, E> = BoxFuture<'a, Result<T, E>>;
