#[allow(unused_imports)]
use crate::errors::{DispatchError, InternalError};
use crate::{
    request::EventRequest,
    response::{EventResponse, ResponseBuilder},
};
use bytes::Bytes;

pub trait Responder {
    fn respond_to(self, req: &EventRequest) -> EventResponse;
}

macro_rules! impl_responder {
    ($res: ty) => {
        impl Responder for $res {
            fn respond_to(self, _: &EventRequest) -> EventResponse { ResponseBuilder::Ok().data(self).build() }
        }
    };
}

impl_responder!(&'static str);
impl_responder!(String);
impl_responder!(&'_ String);
impl_responder!(Bytes);
impl_responder!(());
impl_responder!(Vec<u8>);

impl<T, E> Responder for Result<T, E>
where
    T: Responder,
    E: Into<DispatchError>,
{
    fn respond_to(self, request: &EventRequest) -> EventResponse {
        match self {
            Ok(val) => val.respond_to(request),
            Err(e) => e.into().into(),
        }
    }
}
