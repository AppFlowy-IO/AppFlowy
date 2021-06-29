use std::future::Future;

use crate::{
    error::{InternalError, SystemError},
    module::Event,
    request::payload::Payload,
    util::ready::{ready, Ready},
};
use futures_core::ready;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
    pin::Pin,
    task::{Context, Poll},
};
#[derive(Clone, Debug)]
pub struct EventRequest {
    id: String,
    event: Event,
    data: Option<Vec<u8>>,
}

impl EventRequest {
    pub fn new<E>(event: E) -> EventRequest
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            event: event.into(),
            data: None,
        }
    }

    pub fn data(mut self, data: Vec<u8>) -> Self {
        self.data = Some(data);
        self
    }

    pub fn get_event(&self) -> &Event { &self.event }

    pub fn get_id(&self) -> &str { &self.id }

    pub fn from_data(_data: Vec<u8>) -> Self { unimplemented!() }
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

    fn from_request(req: &EventRequest, _payload: &mut Payload) -> Self::Future {
        match &req.data {
            None => ready(Err(InternalError::new("Expected string but request had data").into())),
            Some(buf) => ready(Ok(String::from_utf8_lossy(buf).into_owned())),
        }
    }
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
