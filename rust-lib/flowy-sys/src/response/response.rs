use crate::{
    error::Error,
    request::FlowyRequest,
    response::{FlowyResponseBuilder, Responder},
};
use std::future::Future;

#[derive(Clone, Copy)]
pub enum StatusCode {
    Success,
    Error,
}

pub enum ResponseData {
    Bytes(Vec<u8>),
    None,
}

pub struct FlowyResponse<T = ResponseData> {
    pub data: T,
    pub status: StatusCode,
    pub error: Option<Error>,
}

impl FlowyResponse {
    pub fn new(status: StatusCode) -> Self {
        FlowyResponse {
            data: ResponseData::None,
            status,
            error: None,
        }
    }

    pub fn success() -> Self {
        FlowyResponse {
            data: ResponseData::None,
            status: StatusCode::Success,
            error: None,
        }
    }

    #[inline]
    pub fn from_error(error: Error) -> FlowyResponse {
        let mut resp = error.as_handler_error().as_response();
        resp.error = Some(error);
        resp
    }
}

impl Responder for FlowyResponse {
    #[inline]
    fn respond_to(self, _: &FlowyRequest) -> FlowyResponse { self }
}

impl std::convert::Into<ResponseData> for String {
    fn into(self) -> ResponseData { ResponseData::Bytes(self.into_bytes()) }
}

impl std::convert::Into<ResponseData> for &str {
    fn into(self) -> ResponseData { self.to_string().into() }
}
