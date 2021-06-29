use std::future::Future;

use crate::{
    error::SystemError,
    module::Event,
    request::payload::Payload,
    util::ready::{ready, Ready},
};
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};

#[derive(Clone, Debug)]
pub struct EventRequest {
    id: String,
    event: Event,
    data: Option<Vec<u8>>,
}

impl EventRequest {
    pub fn new<E>(event: E) -> EventRequest
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            event: event.into(),
            data: None,
        }
    }

    pub fn data(mut self, data: Vec<u8>) -> Self {
        self.data = Some(data);
        self
    }

    pub fn get_event(&self) -> &Event { &self.event }

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
