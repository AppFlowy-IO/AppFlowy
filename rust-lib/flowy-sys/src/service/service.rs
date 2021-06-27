use std::future::Future;

use crate::{
    request::{payload::Payload, EventRequest},
    response::EventResponse,
};

pub trait Service<Request> {
    type Response;
    type Error;
    type Future: Future<Output = Result<Self::Response, Self::Error>>;

    fn call(&self, req: Request) -> Self::Future;
}

pub trait ServiceFactory<Request> {
    type Response;
    type Error;
    type Service: Service<Request, Response = Self::Response, Error = Self::Error>;
    type Config;
    type Future: Future<Output = Result<Self::Service, Self::Error>>;

    fn new_service(&self, cfg: Self::Config) -> Self::Future;
}

pub struct ServiceRequest {
    req: EventRequest,
    payload: Payload,
}

impl ServiceRequest {
    pub fn new(req: EventRequest, payload: Payload) -> Self { Self { req, payload } }

    #[inline]
    pub fn into_parts(self) -> (EventRequest, Payload) { (self.req, self.payload) }
}

pub struct ServiceResponse {
    request: EventRequest,
    response: EventResponse,
}

impl ServiceResponse {
    pub fn new(request: EventRequest, response: EventResponse) -> Self { ServiceResponse { request, response } }

    pub fn into_parts(self) -> (EventRequest, EventResponse) { (self.request, self.response) }
}
