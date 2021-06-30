use std::future::Future;

use crate::{
    error::{InternalError, SystemError},
    module::Event,
    request::{payload::Payload, PayloadError},
    response::Responder,
    util::ready::{ready, Ready},
};
use bytes::Bytes;
use futures_core::{ready, Stream};
use std::{
    fmt::{Debug, Display},
    hash::Hash,
    ops,
    pin::Pin,
    task::{Context, Poll},
};

#[derive(Clone, Debug)]
pub struct EventRequest {
    pub(crate) id: String,
    pub(crate) event: Event,
}

impl EventRequest {
    pub fn new<E>(event: E) -> EventRequest
    where
        E: Into<Event>,
    {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
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
            Payload::None => ready(Err(unexpected_none_payload())),
            Payload::Bytes(buf) => ready(Ok(String::from_utf8_lossy(buf).into_owned())),
        }
    }
}

fn unexpected_none_payload() -> SystemError { InternalError::new("Expected string but request had data").into() }

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

pub struct In<T>(pub T);

impl<T> In<T> {
    pub fn into_inner(self) -> T { self.0 }
}

impl<T> ops::Deref for In<T> {
    type Target = T;

    fn deref(&self) -> &T { &self.0 }
}

impl<T> ops::DerefMut for In<T> {
    fn deref_mut(&mut self) -> &mut T { &mut self.0 }
}

#[cfg(feature = "use_serde")]
impl<T> FromRequest for In<T>
where
    T: serde::de::DeserializeOwned + 'static,
{
    type Error = SystemError;
    type Future = Ready<Result<Self, SystemError>>;

    #[inline]
    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future {
        match payload {
            Payload::None => ready(Err(unexpected_none_payload())),
            Payload::Bytes(bytes) => {
                let data: T = bincode::deserialize(bytes).unwrap();
                ready(Ok(In(data)))
            },
        }
    }
}

#[cfg(feature = "use_protobuf")]
impl<T> FromRequest for In<T>
where
    T: ::protobuf::Message + 'static,
{
    type Error = SystemError;
    type Future = Ready<Result<Self, SystemError>>;

    #[inline]
    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future {
        match payload {
            Payload::None => ready(Err(unexpected_none_payload())),
            Payload::Bytes(bytes) => {
                let data: T = ::protobuf::Message::parse_from_bytes(bytes).unwrap();
                ready(Ok(In(data)))
            },
        }
    }
}
