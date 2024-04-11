use futures_core::future::BoxFuture;
use futures_core::ready;
use pin_project::pin_project;
use std::{
  fmt::Debug,
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

#[pin_project]
pub struct FutureResult<T, E> {
  #[pin]
  pub fut: Pin<Box<dyn Future<Output = Result<T, E>> + Sync + Send>>,
}

impl<T, E> FutureResult<T, E> {
  pub fn new<F>(f: F) -> Self
  where
    F: Future<Output = Result<T, E>> + Send + Sync + 'static,
  {
    Self { fut: Box::pin(f) }
  }
}

impl<T, E> Future for FutureResult<T, E>
where
  T: Send + Sync,
  E: Debug,
{
  type Output = Result<T, E>;

  fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    let this = self.as_mut().project();
    let result = ready!(this.fut.poll(cx));
    Poll::Ready(result)
  }
}

pub type BoxResultFuture<'a, T, E> = BoxFuture<'a, Result<T, E>>;
