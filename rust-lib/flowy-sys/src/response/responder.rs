use crate::{
    request::EventRequest,
    response::{EventResponse, EventResponseBuilder},
};

pub trait Responder {
    fn respond_to(self, req: &EventRequest) -> EventResponse;
}

macro_rules! impl_responder {
    ($res: ty) => {
        impl Responder for $res {
            fn respond_to(self, _: &EventRequest) -> EventResponse { EventResponseBuilder::Ok().data(self).build() }
        }
    };
}

impl_responder!(&'static str);
impl_responder!(String);
