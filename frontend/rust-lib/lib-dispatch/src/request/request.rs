use std::future::Future;
use std::{
  fmt::Debug,
  pin::Pin,
  task::{Context, Poll},
};

use derivative::*;
use futures_core::ready;

use crate::prelude::AFStateMap;
use crate::{
  errors::{DispatchError, InternalError},
  module::AFPluginEvent,
  request::payload::Payload,
  util::ready::{ready, Ready},
};

#[derive(Clone, Debug, Derivative)]
pub struct AFPluginEventRequest {
  #[allow(dead_code)]
  pub(crate) id: String,
  pub(crate) event: AFPluginEvent,
  #[derivative(Debug = "ignore")]
  pub(crate) states: AFStateMap,
}

impl AFPluginEventRequest {
  pub fn new<E>(id: String, event: E, states: AFStateMap) -> AFPluginEventRequest
  where
    E: Into<AFPluginEvent>,
  {
    Self {
      id,
      event: event.into(),
      states,
    }
  }

  pub fn get_state<T>(&self) -> Option<T>
  where
    T: Send + Sync + 'static + Clone,
  {
    if let Some(data) = self.states.get::<T>() {
      return Some(data.clone());
    }

    None
  }
}

pub trait FromAFPluginRequest: Sized {
  type Error: Into<DispatchError>;
  type Future: Future<Output = Result<Self, Self::Error>>;

  fn from_request(req: &AFPluginEventRequest, payload: &mut Payload) -> Self::Future;
}

#[doc(hidden)]
impl FromAFPluginRequest for () {
  type Error = DispatchError;
  type Future = Ready<Result<(), DispatchError>>;

  fn from_request(_req: &AFPluginEventRequest, _payload: &mut Payload) -> Self::Future {
    ready(Ok(()))
  }
}

#[doc(hidden)]
impl FromAFPluginRequest for String {
  type Error = DispatchError;
  type Future = Ready<Result<Self, Self::Error>>;

  fn from_request(req: &AFPluginEventRequest, payload: &mut Payload) -> Self::Future {
    match &payload {
      Payload::None => ready(Err(unexpected_none_payload(req))),
      Payload::Bytes(buf) => ready(Ok(String::from_utf8_lossy(buf).into_owned())),
    }
  }
}

pub fn unexpected_none_payload(request: &AFPluginEventRequest) -> DispatchError {
  tracing::warn!("{:?} expected payload", &request.event);
  InternalError::UnexpectedNone("Expected payload".to_string()).into()
}

#[doc(hidden)]
impl<T> FromAFPluginRequest for Result<T, T::Error>
where
  T: FromAFPluginRequest,
{
  type Error = DispatchError;
  type Future = FromRequestFuture<T::Future>;

  fn from_request(req: &AFPluginEventRequest, payload: &mut Payload) -> Self::Future {
    FromRequestFuture {
      fut: T::from_request(req, payload),
    }
  }
}

#[pin_project::pin_project]
pub struct FromRequestFuture<Fut> {
  #[pin]
  fut: Fut,
}

impl<Fut, T, E> Future for FromRequestFuture<Fut>
where
  Fut: Future<Output = Result<T, E>>,
{
  type Output = Result<Result<T, E>, DispatchError>;

  fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    let this = self.project();
    let res = ready!(this.fut.poll(cx));
    Poll::Ready(Ok(res))
  }
}
