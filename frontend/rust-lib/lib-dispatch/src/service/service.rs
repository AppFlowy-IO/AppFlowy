use std::future::Future;

use crate::{
  request::{payload::Payload, AFPluginEventRequest},
  response::AFPluginEventResponse,
};

pub trait Service<Request> {
  type Response;
  type Error;
  type Future: Future<Output = Result<Self::Response, Self::Error>>;

  fn call(&self, req: Request) -> Self::Future;
}

/// Returns a future that can handle the request. For the moment, the request will be the
/// `AFPluginRequest`
pub trait AFPluginServiceFactory<Request> {
  type Response;
  type Error;
  type Service: Service<Request, Response = Self::Response, Error = Self::Error>;
  type Context;
  type Future: Future<Output = Result<Self::Service, Self::Error>>;

  fn new_service(&self, cfg: Self::Context) -> Self::Future;
}

pub(crate) struct ServiceRequest {
  event_state: AFPluginEventRequest,
  payload: Payload,
}

impl ServiceRequest {
  pub(crate) fn new(event_state: AFPluginEventRequest, payload: Payload) -> Self {
    Self {
      event_state,
      payload,
    }
  }

  #[inline]
  pub(crate) fn into_parts(self) -> (AFPluginEventRequest, Payload) {
    (self.event_state, self.payload)
  }
}

pub struct ServiceResponse {
  request: AFPluginEventRequest,
  response: AFPluginEventResponse,
}

impl ServiceResponse {
  pub fn new(request: AFPluginEventRequest, response: AFPluginEventResponse) -> Self {
    ServiceResponse { request, response }
  }

  pub fn into_parts(self) -> (AFPluginEventRequest, AFPluginEventResponse) {
    (self.request, self.response)
  }
}
