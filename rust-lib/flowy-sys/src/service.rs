use crate::payload::Payload;
use crate::request::FlowyRequest;
use crate::response::{FlowyResponse, Responder, ResponseData};
use std::future::Future;

pub trait Service<Request> {
    type Response;
    type Error;
    type Future: Future<Output = Result<Self::Response, Self::Error>>;

    fn call(&self, req: Request) -> Self::Future;
}

pub trait ServiceFactory<Req> {
    type Response;
    type Error;
    type Service: Service<Req, Response = Self::Response, Error = Self::Error>;
    type InitError;
    type Config;
    type Future: Future<Output = Result<Self::Service, Self::InitError>>;

    fn new_service(&self, cfg: Self::Config) -> Self::Future;
}

pub struct ServiceRequest {
    req: FlowyRequest,
    payload: Payload,
}

impl ServiceRequest {

    pub fn new(req: FlowyRequest, payload: Payload) -> Self {
        Self {
            req, payload,
        }
    }

    #[inline]
    pub fn into_parts(self) -> (FlowyRequest, Payload) {
        (self.req, self.payload)
    }
}

pub struct ServiceResponse<T = ResponseData> {
    request: FlowyRequest,
    response: FlowyResponse<T>,
}

impl<T> ServiceResponse<T> {
    pub fn new(request: FlowyRequest, response: FlowyResponse<T>) -> Self {
        ServiceResponse { request, response }
    }
}
