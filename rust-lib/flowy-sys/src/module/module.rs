use crate::{
    data::container::DataContainer,
    error::SystemError,
    module::ModuleData,
    request::FromRequest,
    response::Responder,
    service::{BoxService, Handler, Service, ServiceFactory, ServiceRequest, ServiceResponse},
};

use crate::{
    error::InternalError,
    request::{payload::Payload, EventRequest},
    response::EventResponse,
    service::{factory, BoxServiceFactory, HandlerService},
};
use futures_core::{future::LocalBoxFuture, ready};
use pin_project::pin_project;
use std::{
    collections::HashMap,
    fmt::{Debug, Display},
    future::Future,
    hash::Hash,
    pin::Pin,
    rc::Rc,
    task::{Context, Poll},
};
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender};

#[derive(PartialEq, Eq, Hash, Debug, Clone)]
pub struct Event(String);

impl<T: Display + Eq + Hash + Debug + Clone> std::convert::From<T> for Event {
    fn from(t: T) -> Self { Event(format!("{}", t)) }
}

pub type EventServiceFactory = BoxServiceFactory<(), ServiceRequest, ServiceResponse, SystemError>;

pub struct Module {
    name: String,
    data: DataContainer,
    service_map: Rc<HashMap<Event, EventServiceFactory>>,
    req_tx: UnboundedSender<EventRequest>,
    req_rx: UnboundedReceiver<EventRequest>,
}

impl Module {
    pub fn new() -> Self {
        let (req_tx, req_rx) = unbounded_channel::<EventRequest>();
        Self {
            name: "".to_owned(),
            data: DataContainer::new(),
            service_map: Rc::new(HashMap::new()),
            req_tx,
            req_rx,
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

    pub fn event<E, H, T, R>(mut self, event: E, handler: H) -> Self
    where
        H: Handler<T, R>,
        T: FromRequest + 'static,
        R: Future + 'static,
        R::Output: Responder + 'static,
        E: Eq + Hash + Debug + Clone + Display,
    {
        let event: Event = event.into();
        if self.service_map.contains_key(&event) {
            log::error!("Duplicate Event: {:?}", &event);
        }

        Rc::get_mut(&mut self.service_map)
            .unwrap()
            .insert(event, factory(HandlerService::new(handler)));
        self
    }

    pub fn req_tx(&self) -> UnboundedSender<EventRequest> { self.req_tx.clone() }

    pub fn handle(&self, request: EventRequest) {
        log::debug!("Module: {} receive request: {:?}", self.name, request);
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

    pub fn events(&self) -> Vec<Event> { self.service_map.keys().map(|key| key.clone()).collect::<Vec<_>>() }
}

impl Future for Module {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.req_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(request) => {
                    let mut service = self.new_service(request.get_id().to_string());
                    if let Ok(service) = ready!(Pin::new(&mut service).poll(cx)) {
                        log::trace!("Spawn module service for request {}", request.get_id());
                        tokio::task::spawn_local(async move {
                            let _ = service.call(request).await;
                        });
                    }
                },
            }
        }
    }
}

impl ServiceFactory<EventRequest> for Module {
    type Response = EventResponse;
    type Error = SystemError;
    type Service = BoxService<EventRequest, Self::Response, Self::Error>;
    type Config = String;
    type Future = LocalBoxFuture<'static, Result<Self::Service, Self::Error>>;

    fn new_service(&self, cfg: Self::Config) -> Self::Future {
        log::trace!("Create module service for request {}", cfg);
        let service_map = self.service_map.clone();
        Box::pin(async move {
            let service = ModuleService { service_map };
            let module_service = Box::new(service) as Self::Service;
            Ok(module_service)
        })
    }
}

pub struct ModuleService {
    service_map: Rc<HashMap<Event, EventServiceFactory>>,
}

impl Service<EventRequest> for ModuleService {
    type Response = EventResponse;
    type Error = SystemError;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn call(&self, request: EventRequest) -> Self::Future {
        log::trace!("Call module service for request {}", request.get_id());
        match self.service_map.get(request.get_event()) {
            Some(factory) => {
                let fut = ModuleServiceFuture {
                    request,
                    fut: factory.new_service(()),
                };
                Box::pin(async move { Ok(fut.await.unwrap_or_else(|e| e.into())) })
            },
            None => Box::pin(async { Err(InternalError::new("".to_string()).into()) }),
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
            log::debug!("Call service to handle request {:?}", self.request);
            let (_, resp) = ready!(Pin::new(&mut service.call(req)).poll(cx))?.into_parts();
            return Poll::Ready(Ok(resp));
        }
    }
}

// #[cfg(test)]
// mod tests {
//     use super::*;
//     use crate::rt::Runtime;
//     use futures_util::{future, pin_mut};
//     use tokio::sync::mpsc::unbounded_channel;
//     pub async fn hello_service() -> String { "hello".to_string() }
//     #[test]
//     fn test() {
//         let runtime = Runtime::new().unwrap();
//         runtime.block_on(async {
//             let (sys_tx, mut sys_rx) = unbounded_channel::<SystemCommand>();
//             let event = "hello".to_string();
//             let module = Module::new(sys_tx).event(event.clone(),
// hello_service);             let req_tx = module.req_tx();
//             let event = async move {
//                 let request = EventRequest::new(event.clone());
//                 req_tx.send(request).unwrap();
//
//                 match sys_rx.recv().await {
//                     Some(cmd) => {
//                         log::info!("{:?}", cmd);
//                     },
//                     None => panic!(""),
//                 }
//             };
//
//             pin_mut!(module, event);
//             future::select(module, event).await;
//         });
//     }
// }
