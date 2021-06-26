use std::future::Future;

use crate::{
    request::{payload::Payload, FlowyRequest},
    response::{data::ResponseData, FlowyResponse},
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
    req: FlowyRequest,
    payload: Payload,
}

impl ServiceRequest {
    pub fn new(req: FlowyRequest, payload: Payload) -> Self { Self { req, payload } }

    #[inline]
    pub fn into_parts(self) -> (FlowyRequest, Payload) { (self.req, self.payload) }
}

pub struct ServiceResponse<T = ResponseData> {
    request: FlowyRequest,
    response: FlowyResponse<T>,
}

impl<T> ServiceResponse<T> {
    pub fn new(request: FlowyRequest, response: FlowyResponse<T>) -> Self { ServiceResponse { request, response } }

    pub fn into_parts(self) -> (FlowyRequest, FlowyResponse<T>) { (self.request, self.response) }
}
