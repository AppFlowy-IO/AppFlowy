#[allow(unused_imports)]
use crate::errors::{DispatchError, InternalError};
use crate::{
  request::AFPluginEventRequest,
  response::{AFPluginEventResponse, ResponseBuilder},
};
use bytes::Bytes;

pub trait AFPluginResponder {
  fn respond_to(self, req: &AFPluginEventRequest) -> AFPluginEventResponse;
}

macro_rules! impl_responder {
  ($res: ty) => {
    impl AFPluginResponder for $res {
      fn respond_to(self, _: &AFPluginEventRequest) -> AFPluginEventResponse {
        ResponseBuilder::Ok().data(self).build()
      }
    }
  };
}

impl_responder!(&'static str);
impl_responder!(String);
impl_responder!(&'_ String);
impl_responder!(Bytes);
impl_responder!(());
impl_responder!(Vec<u8>);

impl<T, E> AFPluginResponder for Result<T, E>
where
  T: AFPluginResponder,
  E: Into<DispatchError>,
{
  fn respond_to(self, request: &AFPluginEventRequest) -> AFPluginEventResponse {
    match self {
      Ok(val) => val.respond_to(request),
      Err(e) => e.into().into(),
    }
  }
}
