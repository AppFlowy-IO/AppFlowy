use crate::{
    request::EventRequest,
    response::{EventResponse, EventResponseBuilder, StatusCode},
};
use dyn_clone::DynClone;
use std::{fmt, option::NoneError};
use tokio::sync::mpsc::error::SendError;

pub trait Error: fmt::Debug + fmt::Display + DynClone {
    fn status_code(&self) -> StatusCode;

    fn as_response(&self) -> EventResponse { EventResponse::new(self.status_code()) }
}

dyn_clone::clone_trait_object!(Error);

impl<T: Error + 'static> From<T> for SystemError {
    fn from(err: T) -> SystemError { SystemError { inner: Box::new(err) } }
}

#[derive(Clone)]
pub struct SystemError {
    inner: Box<dyn Error>,
}

impl SystemError {
    pub fn inner_error(&self) -> &dyn Error { self.inner.as_ref() }
}

impl fmt::Display for SystemError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { fmt::Display::fmt(&self.inner, f) }
}

impl fmt::Debug for SystemError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}", &self.inner) }
}

impl std::error::Error for SystemError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> { None }

    fn cause(&self) -> Option<&dyn std::error::Error> { None }
}

impl From<SendError<EventRequest>> for SystemError {
    fn from(err: SendError<EventRequest>) -> Self {
        InternalError {
            inner: format!("{}", err),
        }
        .into()
    }
}

impl From<NoneError> for SystemError {
    fn from(s: NoneError) -> Self {
        InternalError {
            inner: format!("Unexpected none: {:?}", s),
        }
        .into()
    }
}

impl From<SystemError> for EventResponse {
    fn from(err: SystemError) -> Self { err.inner_error().as_response() }
}

#[derive(Clone)]
pub struct InternalError<T: Clone> {
    inner: T,
}

impl<T: Clone> InternalError<T> {
    pub fn new(inner: T) -> Self { InternalError { inner } }
}

impl<T> fmt::Debug for InternalError<T>
where
    T: fmt::Debug + 'static + Clone,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { fmt::Debug::fmt(&self.inner, f) }
}

impl<T> fmt::Display for InternalError<T>
where
    T: fmt::Debug + fmt::Display + 'static + Clone,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { fmt::Display::fmt(&self.inner, f) }
}

impl<T> Error for InternalError<T>
where
    T: fmt::Debug + fmt::Display + 'static + Clone,
{
    fn status_code(&self) -> StatusCode { StatusCode::Err }

    fn as_response(&self) -> EventResponse { EventResponseBuilder::Err().data(format!("{}", self.inner)).build() }
}
