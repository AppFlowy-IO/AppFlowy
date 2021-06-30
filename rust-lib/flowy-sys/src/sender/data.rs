use crate::{
    module::{Event, ModuleRequest},
    request::{EventRequest, Payload},
    response::EventResponse,
};
use std::{
    fmt::{Debug, Display},
    hash::Hash,
};

#[derive(Debug)]
pub struct SenderPayload {
    pub(crate) payload: Payload,
    pub(crate) event: Event,
}

impl SenderPayload {
    pub fn new<E>(event: E) -> SenderPayload
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        Self {
            event: event.into(),
            payload: Payload::None,
        }
    }

    pub fn payload(mut self, payload: Payload) -> Self {
        self.payload = payload;
        self
    }

    pub fn from_bytes(bytes: Vec<u8>) -> Self { unimplemented!() }
}

impl std::convert::Into<ModuleRequest> for SenderPayload {
    fn into(self) -> ModuleRequest { ModuleRequest::new(self.event).payload(self.payload) }
}

impl std::default::Default for SenderPayload {
    fn default() -> Self { SenderPayload::new("").payload(Payload::None) }
}

impl std::convert::Into<EventRequest> for SenderPayload {
    fn into(self) -> EventRequest { unimplemented!() }
}

pub type BoxStreamCallback<T> = Box<dyn FnOnce(T, EventResponse) + 'static + Send + Sync>;
pub struct SenderData<T>
where
    T: 'static,
{
    pub config: T,
    pub payload: SenderPayload,
    pub callback: Option<BoxStreamCallback<T>>,
}

impl<T> SenderData<T> {
    pub fn new(config: T, payload: SenderPayload) -> Self {
        Self {
            config,
            payload,
            callback: None,
        }
    }

    pub fn callback(mut self, callback: BoxStreamCallback<T>) -> Self {
        self.callback = Some(callback);
        self
    }
}
