use crate::{
    error::SystemError,
    request::EventRequest,
    response::{EventResponse, EventResponseBuilder},
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
                EventResponseBuilder::Ok().data(self).build()
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

pub struct Out<T>(pub T);

impl<T> Out<T> {
    pub fn into_inner(self) -> T { self.0 }
}

impl<T> ops::Deref for Out<T> {
    type Target = T;

    fn deref(&self) -> &T { &self.0 }
}

impl<T> ops::DerefMut for Out<T> {
    fn deref_mut(&mut self) -> &mut T { &mut self.0 }
}

#[cfg(feature = "use_serde")]
impl<T> Responder for Out<T>
where
    T: serde::Serialize,
{
    fn respond_to(self, request: &EventRequest) -> EventResponse {
        let bytes: Vec<u8> = bincode::serialize(&self.0).unwrap();
        EventResponseBuilder::Ok().data(bytes).build()
    }
}

#[cfg(feature = "use_serde")]
impl<T> std::convert::From<T> for Out<T>
where
    T: serde::Serialize,
{
    fn from(val: T) -> Self { Out(val) }
}

#[cfg(feature = "use_protobuf")]
impl<T> Responder for Out<T>
where
    T: ::protobuf::Message,
{
    fn respond_to(self, _request: &EventRequest) -> EventResponse {
        let bytes: Vec<u8> = self.write_to_bytes().unwrap();
        EventResponseBuilder::Ok().data(bytes).build()
    }
}

#[cfg(feature = "use_protobuf")]
impl<T> std::convert::From<T> for Out<T>
where
    T: ::protobuf::Message,
{
    fn from(val: T) -> Self { Out(val) }
}
