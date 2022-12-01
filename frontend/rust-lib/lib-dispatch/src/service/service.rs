use std::future::Future;

use crate::{
    request::{payload::Payload, AFPluginEventRequest},
    response::EventResponse,
};

pub trait Service<Request> {
    type Response;
    type Error;
    type Future: Future<Output = Result<Self::Response, Self::Error>>;

    fn call(&self, req: Request) -> Self::Future;
}

pub trait AFPluginServiceFactory<Request> {
    type Response;
    type Error;
    type Service: Service<Request, Response = Self::Response, Error = Self::Error>;
    type Context;
    type Future: Future<Output = Result<Self::Service, Self::Error>>;

    fn new_service(&self, cfg: Self::Context) -> Self::Future;
}

pub(crate) struct ServiceRequest {
    req: AFPluginEventRequest,
    payload: Payload,
}

impl ServiceRequest {
    pub(crate) fn new(req: AFPluginEventRequest, payload: Payload) -> Self {
        Self { req, payload }
    }

    #[inline]
    pub(crate) fn into_parts(self) -> (AFPluginEventRequest, Payload) {
        (self.req, self.payload)
    }
}

pub struct ServiceResponse {
    request: AFPluginEventRequest,
    response: EventResponse,
}

impl ServiceResponse {
    pub fn new(request: AFPluginEventRequest, response: EventResponse) -> Self {
        ServiceResponse { request, response }
    }

    pub fn into_parts(self) -> (AFPluginEventRequest, EventResponse) {
        (self.request, self.response)
    }
}
