use crate::{
    error::Error,
    handler::{boxed, BoxServiceFactory, Handler, HandlerService},
    request::FromRequest,
    response::Responder,
    service::{ServiceRequest, ServiceResponse},
};

use std::{
    future::Future,
    pin::Pin,
    task::{Context, Poll},
};

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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{payload::Payload, request::FlowyRequest, service::ServiceFactory};

    pub async fn no_params() -> String {
        println!("no params");
        "hello".to_string()
    }
    #[tokio::test]
    async fn extract_no_params() {
        let dispatch = HandlerDispatch::new(no_params);
        let resp = response_from_dispatch(dispatch).await;
    }

    pub async fn one_params(s: String) -> String {
        println!("one params");
        "hello".to_string()
    }

    #[tokio::test]
    async fn extract_one_params() {
        let dispatch = HandlerDispatch::new(one_params);
        let resp = response_from_dispatch(dispatch).await;
    }

    async fn response_from_dispatch(dispatch: HandlerDispatch) -> ServiceResponse {
        let service = dispatch.service.new_service(()).await.unwrap();
        let service_request = ServiceRequest::new(FlowyRequest::default(), Payload::None);
        let resp = service.call(service_request).await.unwrap();
        resp
    }
}
