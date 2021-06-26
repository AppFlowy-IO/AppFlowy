use std::future::Future;

use crate::{
    error::SystemError,
    request::payload::Payload,
    util::ready::{ready, Ready},
};
use std::hash::Hash;

#[derive(Clone, Debug)]
pub struct FlowyRequest {
    id: String,
    cmd: String,
}

impl FlowyRequest {
    pub fn new(cmd: String) -> FlowyRequest {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            cmd,
        }
    }
}

impl FlowyRequest {
    pub fn get_cmd(&self) -> &str { &self.cmd }
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
