use crate::{
    byte_trait::FromBytes,
    request::EventRequest,
    response::{EventResponse, ResponseBuilder},
};
use bytes::Bytes;
use dyn_clone::DynClone;

use serde::{Serialize, Serializer};
use std::fmt;
use tokio::{sync::mpsc::error::SendError, task::JoinError};

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
        InternalError::Other(format!("{}", err)).into()
    }
}

impl From<String> for DispatchError {
    fn from(s: String) -> Self { InternalError::Other(s).into() }
}

#[cfg(feature = "use_protobuf")]
impl From<protobuf::ProtobufError> for DispatchError {
    fn from(e: protobuf::ProtobufError) -> Self {
        InternalError::ProtobufError(format!("{:?}", e)).into()
    }
}

impl FromBytes for DispatchError {
    fn parse_from_bytes(bytes: Bytes) -> Result<Self, DispatchError> {
        let s = String::from_utf8(bytes.to_vec()).unwrap();
        Ok(InternalError::DeserializeFromBytes(s).into())
    }
}

impl From<DispatchError> for EventResponse {
    fn from(err: DispatchError) -> Self { err.inner_error().as_response() }
}

impl Serialize for DispatchError {
    fn serialize<S>(&self, serializer: S) -> Result<<S as Serializer>::Ok, <S as Serializer>::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&format!("{}", self))
    }
}

#[derive(Clone, Debug)]
pub(crate) enum InternalError {
    ProtobufError(String),
    UnexpectedNone(String),
    DeserializeFromBytes(String),
    SerializeToBytes(String),
    JoinError(String),
    Lock(String),
    ServiceNotFound(String),
    HandleNotFound(String),
    Other(String),
}

impl fmt::Display for InternalError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            InternalError::ProtobufError(s) => fmt::Display::fmt(&s, f),
            InternalError::UnexpectedNone(s) => fmt::Display::fmt(&s, f),
            InternalError::DeserializeFromBytes(s) => fmt::Display::fmt(&s, f),
            InternalError::SerializeToBytes(s) => fmt::Display::fmt(&s, f),
            InternalError::JoinError(s) => fmt::Display::fmt(&s, f),
            InternalError::Lock(s) => fmt::Display::fmt(&s, f),
            InternalError::ServiceNotFound(s) => fmt::Display::fmt(&s, f),
            InternalError::HandleNotFound(s) => fmt::Display::fmt(&s, f),
            InternalError::Other(s) => fmt::Display::fmt(&s, f),
        }
    }
}

impl Error for InternalError {
    fn as_response(&self) -> EventResponse {
        let error = format!("{}", self).into_bytes();
        ResponseBuilder::Err().data(error).build()
    }
}

impl std::convert::From<JoinError> for InternalError {
    fn from(e: JoinError) -> Self { InternalError::JoinError(format!("{}", e)) }
}
