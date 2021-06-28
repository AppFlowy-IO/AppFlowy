use std::future::Future;

use crate::{
    error::SystemError,
    request::payload::Payload,
    util::ready::{ready, Ready},
};

#[derive(Clone, Debug)]
pub struct EventRequest {
    id: String,
    event: String,
    data: Option<Vec<u8>>,
}

impl EventRequest {
    pub fn new(event: String) -> EventRequest {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            event,
            data: None,
        }
    }

    pub fn data(mut self, data: Vec<u8>) -> Self {
        self.data = Some(data);
        self
    }

    pub fn get_event(&self) -> &str { &self.event }

    pub fn get_id(&self) -> &str { &self.id }

    pub fn from_data(_data: Vec<u8>) -> Self { unimplemented!() }
}

pub trait FromRequest: Sized {
    type Error: Into<SystemError>;
    type Future: Future<Output = Result<Self, Self::Error>>;

    fn from_request(req: &EventRequest, payload: &mut Payload) -> Self::Future;
}

#[doc(hidden)]
impl FromRequest for () {
    type Error = SystemError;
    type Future = Ready<Result<(), SystemError>>;

    fn from_request(_req: &EventRequest, _payload: &mut Payload) -> Self::Future { ready(Ok(())) }
}

#[doc(hidden)]
impl FromRequest for String {
    type Error = SystemError;
    type Future = Ready<Result<String, SystemError>>;

    fn from_request(_req: &EventRequest, _payload: &mut Payload) -> Self::Future { ready(Ok("".to_string())) }
}
