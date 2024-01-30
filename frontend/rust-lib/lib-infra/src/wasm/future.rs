use futures_core::future::LocalBoxFuture;
use futures_core::ready;
use pin_project::pin_project;
use std::{
  fmt::Debug,
  future::Future,
  pin::Pin,
  task::{Context, Poll},
};

#[allow(dead_code)]
pub fn to_fut<T, O>(f: T) -> Fut<O>
where
  T: Future<Output = O> + 'static,
{
  Fut { fut: Box::pin(f) }
}

#[pin_project]
pub struct Fut<T> {
  #[pin]
  pub fut: Pin<Box<dyn Future<Output = T>>>,
}

impl<T> Future for Fut<T> {
  type Output = T;

  fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    let this = self.as_mut().project();
    Poll::Ready(ready!(this.fut.poll(cx)))
  }
}

#[allow(dead_code)]
#[pin_project]
pub struct FutureResult<T, E> {
  #[pin]
  pub fut: Pin<Box<dyn Future<Output = Result<T, E>>>>,
}

impl<T, E> FutureResult<T, E> {
  #[allow(dead_code)]
  pub fn new<F>(f: F) -> Self
  where
    F: Future<Output = Result<T, E>> + 'static,
  {
    Self { fut: Box::pin(f) }
  }
}

impl<T, E> Future for FutureResult<T, E>
where
  E: Debug,
{
  type Output = Result<T, E>;

  fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    let this = self.as_mut().project();
    let result = ready!(this.fut.poll(cx));
    Poll::Ready(result)
  }
}

#[allow(dead_code)]
pub type BoxResultFuture<'a, T, E> = LocalBoxFuture<'a, Result<T, E>>;
