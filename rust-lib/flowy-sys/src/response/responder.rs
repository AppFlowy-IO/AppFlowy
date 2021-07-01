use crate::{
    error::SystemError,
    request::{Data, EventRequest},
    response::{EventResponse, ResponseBuilder},
};
use bytes::Bytes;
use std::ops;

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
    fn into_bytes(self) -> Result<Vec<u8>, SystemError>;
}

#[cfg(feature = "use_serde")]
impl<T> Responder for Data<T>
where
    T: serde::Serialize,
{
    fn respond_to(self, _request: &EventRequest) -> EventResponse {
        let bytes: Vec<u8> = bincode::serialize(&self.0).unwrap();
        ResponseBuilder::Ok().data(bytes).build()
    }
}

#[cfg(feature = "use_serde")]
impl<T> std::convert::From<T> for Data<T>
where
    T: serde::Serialize,
{
    fn from(val: T) -> Self { Data(val) }
}

#[cfg(not(feature = "use_serde"))]
impl<T> Responder for Data<T>
where
    T: ToBytes,
{
    fn respond_to(self, _request: &EventRequest) -> EventResponse {
        match self.into_inner().into_bytes() {
            Ok(bytes) => ResponseBuilder::Ok().data(bytes.to_vec()).build(),
            Err(e) => e.into(),
        }
    }
}

#[cfg(not(feature = "use_serde"))]
impl<T> std::convert::From<T> for Data<T>
where
    T: ToBytes,
{
    fn from(val: T) -> Self { Data(val) }
}
