use crate::{
    error::Error,
    payload::Payload,
    util::ready::{ready, Ready},
};
use std::future::Future;

pub struct FlowyRequest {}

impl std::default::Default for FlowyRequest {
    fn default() -> Self { Self {} }
}

pub trait FromRequest: Sized {
    type Error: Into<Error>;
    type Future: Future<Output = Result<Self, Self::Error>>;

    fn from_request(req: &FlowyRequest, payload: &mut Payload) -> Self::Future;
}

#[doc(hidden)]
impl FromRequest for () {
    type Error = Error;
    type Future = Ready<Result<(), Error>>;

    fn from_request(req: &FlowyRequest, payload: &mut Payload) -> Self::Future { ready(Ok(())) }
}

#[doc(hidden)]
impl FromRequest for String {
    type Error = Error;
    type Future = Ready<Result<String, Error>>;

    fn from_request(req: &FlowyRequest, payload: &mut Payload) -> Self::Future { ready(Ok("".to_string())) }
}
