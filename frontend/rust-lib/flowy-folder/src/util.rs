#![allow(clippy::type_complexity)]
use crate::event_map::{FolderCouldServiceV1, WorkspaceUser};
use lib_infra::retry::Action;
use pin_project::pin_project;
use std::{
  future::Future,
  marker::PhantomData,
  pin::Pin,
  sync::Arc,
  task::{Context, Poll},
};

pub(crate) type Builder<Fut> =
  Box<dyn Fn(String, Arc<dyn FolderCouldServiceV1>) -> Fut + Send + Sync>;

#[allow(dead_code)]
pub(crate) struct RetryAction<Fut, T, E> {
  token: String,
  cloud_service: Arc<dyn FolderCouldServiceV1>,
  user: Arc<dyn WorkspaceUser>,
  builder: Builder<Fut>,
  phantom: PhantomData<(T, E)>,
}

impl<Fut, T, E> RetryAction<Fut, T, E> {
  #[allow(dead_code)]
  pub(crate) fn new<F>(
    cloud_service: Arc<dyn FolderCouldServiceV1>,
    user: Arc<dyn WorkspaceUser>,
    builder: F,
  ) -> Self
  where
    Fut: Future<Output = Result<T, E>> + Send + Sync + 'static,
    F: Fn(String, Arc<dyn FolderCouldServiceV1>) -> Fut + Send + Sync + 'static,
  {
    let token = user.token().unwrap_or_else(|_| "".to_owned());
    Self {
      token,
      cloud_service,
      user,
      builder: Box::new(builder),
      phantom: PhantomData,
    }
  }
}

impl<Fut, T, E> Action for RetryAction<Fut, T, E>
where
  Fut: Future<Output = Result<T, E>> + Send + Sync + 'static,
  T: Send + Sync + 'static,
  E: Send + Sync + 'static,
{
  type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send + Sync>>;
  type Item = T;
  type Error = E;

  fn run(&mut self) -> Self::Future {
    let fut = (self.builder)(self.token.clone(), self.cloud_service.clone());
    Box::pin(RetryActionFut { fut: Box::pin(fut) })
  }
}

#[pin_project]
struct RetryActionFut<T, E> {
  #[pin]
  fut: Pin<Box<dyn Future<Output = Result<T, E>> + Send + Sync>>,
}

impl<T, E> Future for RetryActionFut<T, E>
where
  T: Send + Sync + 'static,
  E: Send + Sync + 'static,
{
  type Output = Result<T, E>;

  fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    let mut this = self.project();
    this.fut.as_mut().poll(cx)
  }
}
