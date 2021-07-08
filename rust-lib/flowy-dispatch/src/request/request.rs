use std::future::Future;

use crate::{
    error::{InternalError, SystemError},
    module::Event,
    request::payload::Payload,
    util::ready::{ready, Ready},
};

use futures_core::ready;
use std::{
    fmt::Debug,
    pin::Pin,
    task::{Context, Poll},
};

#[derive(Clone, Debug)]
pub struct EventRequest {
    pub(crate) id: String,
    pub(crate) event: Event,
}

impl EventRequest {
    pub fn new<E>(event: E, id: String) -> EventRequest
    where
        E: Into<Event>,
    {
        Self {
            id,
            event: event.into(),
        }
    }
}

pub trait FromRequest: Sized {
    type Error: Into<SystemError>;
    type Future: Future<Output = Result<Self, Self::Error>>;

    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future;
}

#[doc(hidden)]
impl FromRequest for () {
    type Error = SystemError;
    type Future = Ready<Result<(), SystemError>>;

    fn from_request(_req: &EventRequest, _payload: &mut Payload) -> Self::Future { ready(Ok(())) }
}

#[doc(hidden)]
impl FromRequest for String {
    type Error = SystemError;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future {
        match &payload {
            Payload::None => ready(Err(unexpected_none_payload(req))),
            Payload::Bytes(buf) => ready(Ok(String::from_utf8_lossy(buf).into_owned())),
        }
    }
}

pub fn unexpected_none_payload(request: &EventRequest) -> SystemError {
    log::warn!("{:?} expected payload", &request.event);
    InternalError::new("Expected payload").into()
}

#[doc(hidden)]
impl<T> FromRequest for Result<T, T::Error>
where
    T: FromRequest,
{
    type Error = SystemError;
    type Future = FromRequestFuture<T::Future>;

    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future {
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
    type Output = Result<Result<T, E>, SystemError>;

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let this = self.project();
        let res = ready!(this.fut.poll(cx));
        Poll::Ready(Ok(res))
    }
}
