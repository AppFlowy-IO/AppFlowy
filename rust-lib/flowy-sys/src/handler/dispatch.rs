use crate::error::Error;
use crate::handler::{boxed, BoxServiceFactory, FromRequest, Handler, HandlerService};
use crate::response::Responder;
use crate::service::{ServiceRequest, ServiceResponse};
use std::future::Future;

pub struct HandlerDispatch {
    service: BoxServiceFactory<(), ServiceRequest, ServiceResponse, Error, ()>,
}

impl HandlerDispatch {
    pub fn new<H, T, R>(handler: H) -> Self
    where
        H: Handler<T, R>,
        T: FromRequest + 'static,
        R: Future + 'static,
        R::Output: Responder + 'static,
    {
        HandlerDispatch {
            service: boxed::factory(HandlerService::new(handler)),
        }
    }
}

pub fn not_found() -> String {
    "hello".to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn extract_string() {
        let dispatch = HandlerDispatch::new(not_found);
    }
}
