use futures_core::ready;
use pin_project::pin_project;
use std::{
    fmt::Debug,
    future::Future,
    pin::Pin,
    task::{Context, Poll},
};

#[pin_project]
pub struct ClosureFuture<T> {
    #[pin]
    pub fut: Pin<Box<dyn Future<Output = T> + Sync + Send>>,
}

impl<T> Future for ClosureFuture<T>
where
    T: Send + Sync,
{
    type Output = T;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let this = self.as_mut().project();
        loop {
            return Poll::Ready(ready!(this.fut.poll(cx)));
        }
    }
}

#[pin_project]
pub struct ResultFuture<T, E> {
    #[pin]
    pub fut: Pin<Box<dyn Future<Output = Result<T, E>> + Sync + Send>>,
}

impl<T, E> ResultFuture<T, E> {
    pub fn new<F>(f: F) -> Self
    where
        F: Future<Output = Result<T, E>> + Send + Sync + 'static,
    {
        Self {
            fut: Box::pin(async { f.await }),
        }
    }
}

impl<T, E> Future for ResultFuture<T, E>
where
    T: Send + Sync,
    E: Debug,
{
    type Output = Result<T, E>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let this = self.as_mut().project();
        loop {
            let result = ready!(this.fut.poll(cx));
            return Poll::Ready(result);
        }
    }
}
