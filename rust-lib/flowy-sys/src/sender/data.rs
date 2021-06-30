use crate::{module::Event, request::Payload, response::EventResponse};
use derivative::*;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};
// #[derive(Debug)]
// pub struct SenderPayload {
//     pub(crate) payload: Payload,
//     pub(crate) event: Event,
// }
//
// impl SenderPayload {
//     pub fn new<E>(event: E) -> SenderPayload
//     where
//         E: Eq + Hash + Debug + Clone + Display,
//     {
//         Self {
//             event: event.into(),
//             payload: Payload::None,
//         }
//     }
//
//     pub fn payload(mut self, payload: Payload) -> Self {
//         self.payload = payload;
//         self
//     }
//
//     pub fn from_bytes(bytes: Vec<u8>) -> Self { unimplemented!() }
// }
//
// impl std::convert::Into<ModuleRequest> for SenderPayload {
//     fn into(self) -> ModuleRequest {
// ModuleRequest::new(self.event).payload(self.payload) } }
//
// impl std::default::Default for SenderPayload {
//     fn default() -> Self { SenderPayload::new("").payload(Payload::None) }
// }
//
// impl std::convert::Into<EventRequest> for SenderPayload {
//     fn into(self) -> EventRequest { unimplemented!() }
// }

pub type BoxStreamCallback<T> = Box<dyn FnOnce(T, EventResponse) + 'static + Send + Sync>;

// #[derive(Debug)]
// pub struct SenderRequest2<T, C>
// where
//     T: 'static + Debug,
//     C: FnOnce(T, EventResponse) + 'static,
// {
//     pub config: T,
//     pub event: Event,
//     pub payload: Option<Payload>,
//     pub callback: Box<dyn C>,
// }

#[derive(Derivative)]
#[derivative(Debug)]
pub struct SenderRequest<T>
where
    T: 'static + Debug,
{
    pub config: T,
    pub event: Event,
    pub payload: Option<Payload>,
    #[derivative(Debug = "ignore")]
    pub callback: Option<BoxStreamCallback<T>>,
}

impl<T> SenderRequest<T>
where
    T: 'static + Debug,
{
    pub fn new<E>(config: T, event: E) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        Self {
            config,
            payload: None,
            event: event.into(),
            callback: None,
        }
    }

    pub fn payload(mut self, payload: Payload) -> Self {
        self.payload = Some(payload);
        self
    }

    pub fn callback<F>(mut self, callback: F) -> Self
    where
        F: FnOnce(T, EventResponse) + 'static + Send + Sync,
    {
        self.callback = Some(Box::new(callback));
        self
    }
}
