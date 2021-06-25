use std::future::Future;

use crate::{
    error::SystemError,
    request::payload::Payload,
    util::ready::{ready, Ready},
};
use std::hash::Hash;

pub struct FlowyRequest {
    id: String,
}

impl FlowyRequest {
    pub fn get_id(&self) -> &str { &self.id }
}

impl std::default::Default for FlowyRequest {
    fn default() -> Self { Self { id: "".to_string() } }
}

pub trait FromRequest: Sized {
    type Error: Into<SystemError>;
    type Future: Future<Output = Result<Self, Self::Error>>;

    fn from_request(req: &FlowyRequest, payload: &mut Payload) -> Self::Future;
}

#[doc(hidden)]
impl FromRequest for () {
    type Error = SystemError;
    type Future = Ready<Result<(), SystemError>>;

    fn from_request(_req: &FlowyRequest, _payload: &mut Payload) -> Self::Future { ready(Ok(())) }
}

#[doc(hidden)]
impl FromRequest for String {
    type Error = SystemError;
    type Future = Ready<Result<String, SystemError>>;

    fn from_request(_req: &FlowyRequest, _payload: &mut Payload) -> Self::Future { ready(Ok("".to_string())) }
}
