#[allow(unused_imports)]
use crate::error::{InternalError, SystemError};
use crate::{
    request::{Data, EventRequest},
    response::{EventResponse, ResponseBuilder},
};
use bytes::Bytes;

pub trait Responder {
    fn respond_to(self, req: &EventRequest) -> EventResponse;
}

macro_rules! impl_responder {
    ($res: ty) => {
        impl Responder for $res {
            fn respond_to(self, _: &EventRequest) -> EventResponse {
                ResponseBuilder::Ok().data(self).build()
            }
        }
    };
}

impl_responder!(&'static str);
impl_responder!(String);
impl_responder!(&'_ String);
impl_responder!(Bytes);

impl<T, E> Responder for Result<T, E>
where
    T: Responder,
    E: Into<SystemError>,
{
    fn respond_to(self, request: &EventRequest) -> EventResponse {
        match self {
            Ok(val) => val.respond_to(request),
            Err(e) => e.into().into(),
        }
    }
}

pub trait ToBytes {
    fn into_bytes(self) -> Result<Vec<u8>, String>;
}

#[cfg(feature = "use_protobuf")]
impl<T> ToBytes for T
where
    T: std::convert::TryInto<Vec<u8>, Error = String>,
{
    fn into_bytes(self) -> Result<Vec<u8>, String> { self.try_into() }
}

#[cfg(feature = "use_serde")]
impl<T> ToBytes for T
where
    T: serde::Serialize,
{
    fn into_bytes(self) -> Result<Vec<u8>, String> {
        match serde_json::to_string(&self.0) {
            Ok(s) => Ok(s.into_bytes()),
            Err(e) => Err(format!("{:?}", e)),
        }
    }
}

impl<T> Responder for Data<T>
where
    T: ToBytes,
{
    fn respond_to(self, _request: &EventRequest) -> EventResponse {
        match self.into_inner().into_bytes() {
            Ok(bytes) => ResponseBuilder::Ok().data(bytes.to_vec()).build(),
            Err(e) => {
                let system_err: SystemError = InternalError::new(format!("{:?}", e)).into();
                system_err.into()
            },
        }
    }
}

impl<T> std::convert::From<T> for Data<T>
where
    T: ToBytes,
{
    fn from(val: T) -> Self { Data(val) }
}
