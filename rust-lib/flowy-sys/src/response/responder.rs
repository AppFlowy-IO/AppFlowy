use crate::{
    error::SystemError,
    request::EventRequest,
    response::{EventResponse, EventResponseBuilder},
};
use bytes::Bytes;

pub trait Responder {
    fn respond_to(self, req: &EventRequest) -> EventResponse;
}

macro_rules! impl_responder {
    ($res: ty) => {
        impl Responder for $res {
            fn respond_to(self, _: &EventRequest) -> EventResponse { EventResponseBuilder::Ok().data(self).build() }
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

// #[cfg(feature = "use_serde")]
// impl<T> Responder for T
// where
//     T: serde::Serialize,
// {
//     fn respond_to(self, request: &EventRequest) -> EventResponse {
//         let bytes = bincode::serialize(&self).unwrap();
//         EventResponseBuilder::Ok().data(bytes).build()
//     }
// }
