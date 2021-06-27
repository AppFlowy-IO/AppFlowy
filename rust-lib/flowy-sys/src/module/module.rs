use crate::{
    data::container::DataContainer,
    error::SystemError,
    module::ModuleData,
    request::FromRequest,
    response::Responder,
    service::{BoxService, Handler, Service, ServiceFactory, ServiceRequest, ServiceResponse},
};

use crate::{
    request::{payload::Payload, EventRequest},
    response::EventResponse,
    service::{factory, BoxServiceFactory, HandlerService},
};
use futures_core::{future::LocalBoxFuture, ready};
use pin_project::pin_project;
use std::{
    collections::HashMap,
    future::Future,
    pin::Pin,
    task::{Context, Poll},
};
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};

pub type Event = String;
pub type EventServiceFactory = BoxServiceFactory<(), ServiceRequest, ServiceResponse, SystemError>;

pub struct Module {
    name: String,
    data: DataContainer,
    service_map: HashMap<Event, EventServiceFactory>,
    req_tx: UnboundedSender<EventRequest>,
    req_rx: UnboundedReceiver<EventRequest>,
    resp_tx: UnboundedSender<EventResponse>,
}

impl Module {
    pub fn new(resp_tx: UnboundedSender<EventResponse>) -> Self {
        let (req_tx, req_rx) = unbounded_channel::<EventRequest>();
        Self {
            name: "".to_owned(),
            data: DataContainer::new(),
            service_map: HashMap::new(),
            req_tx,
            req_rx,
            resp_tx,
        }
    }

    pub fn name(mut self, s: &str) -> Self {
        self.name = s.to_owned();
        self
    }

    pub fn data<D: 'static>(mut self, data: D) -> Self {
        self.data.insert(ModuleData::new(data));
        self
    }

    pub fn event<H, T, R>(mut self, event: Event, handler: H) -> Self
    where
        H: Handler<T, R>,
        T: FromRequest + 'static,
        R: Future + 'static,
        R::Output: Responder + 'static,
    {
        if self.service_map.contains_key(&event) {
            log::error!("Duplicate Event: {}", &event);
        }

        self.service_map.insert(event, factory(HandlerService::new(handler)));
        self
    }

    pub fn req_tx(&self) -> UnboundedSender<EventRequest> { self.req_tx.clone() }

    pub fn handle(&self, request: EventRequest) {
        log::trace!("Module: {} receive request: {:?}", self.name, request);
        match self.req_tx.send(request) {
            Ok(_) => {},
            Err(e) => {
                log::error!("Module: {} with error: {:?}", self.name, e);
            },
        }
    }

    pub fn forward_map(&self) -> HashMap<Event, UnboundedSender<EventRequest>> {
        self.service_map
            .keys()
            .map(|key| (key.clone(), self.req_tx()))
            .collect::<HashMap<_, _>>()
    }
}

impl Future for Module {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.req_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(request) => match self.service_map.get(request.get_event()) {
                    Some(factory) => {
                        let fut = ModuleServiceFuture {
                            request,
                            fut: factory.new_service(()),
                        };
                        let resp_tx = self.resp_tx.clone();
                        tokio::task::spawn_local(async move {
                            let resp = fut.await.unwrap_or_else(|_e| panic!());
                            if let Err(e) = resp_tx.send(resp) {
                                log::error!("{:?}", e);
                            }
                        });
                    },
                    None => {
                        log::error!("Event: {} handler not found", request.get_event());
                    },
                },
            }
        }
    }
}

type BoxModuleService = BoxService<ServiceRequest, ServiceResponse, SystemError>;
#[pin_project]
pub struct ModuleServiceFuture {
    request: EventRequest,
    #[pin]
    fut: LocalBoxFuture<'static, Result<BoxModuleService, SystemError>>,
}

impl Future for ModuleServiceFuture {
    type Output = Result<EventResponse, SystemError>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            let service = ready!(self.as_mut().project().fut.poll(cx))?;
            let req = ServiceRequest::new(self.as_mut().request.clone(), Payload::None);
            log::trace!("Call service to handle request {:?}", self.request);
            let (_, resp) = ready!(Pin::new(&mut service.call(req)).poll(cx))?.into_parts();
            return Poll::Ready(Ok(resp));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::rt::Runtime;
    use futures_util::{future, pin_mut};
    use tokio::sync::mpsc::unbounded_channel;

    pub async fn hello_service() -> String { "hello".to_string() }

    #[test]
    fn test() {
        let mut runtime = Runtime::new().unwrap();
        runtime.block_on(async {
            let (resp_tx, mut resp_rx) = unbounded_channel::<EventResponse>();
            let event = "hello".to_string();
            let mut module = Module::new(resp_tx).event(event.clone(), hello_service);
            let req_tx = module.req_tx();
            let mut event = async move {
                let request = EventRequest::new(event.clone());
                req_tx.send(request).unwrap();

                match resp_rx.recv().await {
                    Some(resp) => {
                        log::info!("{}", resp);
                    },
                    None => panic!(""),
                }
            };

            pin_mut!(module, event);
            future::select(module, event).await;
        });
    }
}
