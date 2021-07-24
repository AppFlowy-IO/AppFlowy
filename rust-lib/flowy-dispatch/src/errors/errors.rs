use crate::{
    byte_trait::FromBytes,
    request::EventRequest,
    response::{EventResponse, ResponseBuilder, StatusCode},
};
use dyn_clone::DynClone;
use serde::{Serialize, Serializer};
use std::{fmt, option::NoneError};
use tokio::sync::mpsc::error::SendError;

pub trait Error: fmt::Debug + DynClone + Send + Sync {
    fn as_response(&self) -> EventResponse;
}

dyn_clone::clone_trait_object!(Error);

impl<T: Error + 'static> From<T> for DispatchError {
    fn from(err: T) -> DispatchError {
        DispatchError {
            inner: Box::new(err),
        }
    }
}

#[derive(Clone)]
pub struct DispatchError {
    inner: Box<dyn Error>,
}

impl DispatchError {
    pub fn inner_error(&self) -> &dyn Error { self.inner.as_ref() }
}

impl fmt::Display for DispatchError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}", &self.inner) }
}

impl fmt::Debug for DispatchError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}", &self.inner) }
}

impl std::error::Error for DispatchError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> { None }

    fn cause(&self) -> Option<&dyn std::error::Error> { None }
}

impl From<SendError<EventRequest>> for DispatchError {
    fn from(err: SendError<EventRequest>) -> Self {
        InternalError {
            inner: format!("{}", err),
        }
        .into()
    }
}

impl From<NoneError> for DispatchError {
    fn from(s: NoneError) -> Self {
        InternalError {
            inner: format!("Unexpected none: {:?}", s),
        }
        .into()
    }
}

impl From<String> for DispatchError {
    fn from(s: String) -> Self { InternalError { inner: s }.into() }
}

impl FromBytes for DispatchError {
    fn parse_from_bytes(bytes: &Vec<u8>) -> Result<Self, String> {
        let s = String::from_utf8(bytes.to_vec()).unwrap();
        Ok(InternalError { inner: s }.into())
    }
}

impl From<DispatchError> for EventResponse {
    fn from(err: DispatchError) -> Self { err.inner_error().as_response() }
}

#[derive(Clone)]
pub(crate) struct InternalError<T: Clone> {
    inner: T,
}

impl<T: Clone> InternalError<T> {
    pub fn new(inner: T) -> Self { InternalError { inner } }
}

impl<T> fmt::Debug for InternalError<T>
where
    T: fmt::Debug + 'static + Clone + Send + Sync,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { fmt::Debug::fmt(&self.inner, f) }
}

impl<T> fmt::Display for InternalError<T>
where
    T: fmt::Debug + fmt::Display + 'static + Clone + Send + Sync,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { fmt::Display::fmt(&self.inner, f) }
}

impl<T> Error for InternalError<T>
where
    T: fmt::Debug + fmt::Display + 'static + Clone + Send + Sync,
{
    fn as_response(&self) -> EventResponse {
        let error = format!("{}", self.inner).into_bytes();
        ResponseBuilder::Err().data(error).build()
    }
}

impl Serialize for DispatchError {
    fn serialize<S>(&self, serializer: S) -> Result<<S as Serializer>::Ok, <S as Serializer>::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&format!("{}", self))
    }
}
