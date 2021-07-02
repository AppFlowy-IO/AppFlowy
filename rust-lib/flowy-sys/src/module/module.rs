use std::{
    collections::HashMap,
    fmt::{Debug, Display},
    future::Future,
    hash::Hash,
    pin::Pin,
    task::{Context, Poll},
};

use futures_core::ready;
use pin_project::pin_project;

use crate::{
    error::{InternalError, SystemError},
    module::{container::DataContainer, ModuleData},
    request::{payload::Payload, EventRequest, FromRequest},
    response::{EventResponse, Responder},
    service::{
        factory,
        BoxService,
        BoxServiceFactory,
        Handler,
        HandlerService,
        Service,
        ServiceFactory,
        ServiceRequest,
        ServiceResponse,
    },
};
use futures_core::future::BoxFuture;
use std::sync::Arc;

pub type ModuleMap = Arc<HashMap<Event, Arc<Module>>>;
pub(crate) fn as_module_map(modules: Vec<Module>) -> ModuleMap {
    let mut module_map = HashMap::new();
    modules.into_iter().for_each(|m| {
        let events = m.events();
        let module = Arc::new(m);
        events.into_iter().for_each(|e| {
            module_map.insert(e, module.clone());
        });
    });
    Arc::new(module_map)
}

#[derive(PartialEq, Eq, Hash, Debug, Clone)]
pub struct Event(String);

impl<T: Display + Eq + Hash + Debug + Clone> std::convert::From<T> for Event {
    fn from(t: T) -> Self { Event(format!("{}", t)) }
}

pub type EventServiceFactory = BoxServiceFactory<(), ServiceRequest, ServiceResponse, SystemError>;

pub struct Module {
    name: String,
    data: DataContainer,
    service_map: Arc<HashMap<Event, EventServiceFactory>>,
}

impl Module {
    pub fn new() -> Self {
        Self {
            name: "".to_owned(),
            data: DataContainer::new(),
            service_map: Arc::new(HashMap::new()),
        }
    }

    pub fn name(mut self, s: &str) -> Self {
        self.name = s.to_owned();
        self
    }

    pub fn data<D: 'static + Send + Sync>(mut self, data: D) -> Self {
        self.data.insert(ModuleData::new(data));
        self
    }

    pub fn event<E, H, T, R>(mut self, event: E, handler: H) -> Self
    where
        H: Handler<T, R>,
        T: FromRequest + 'static + Send + Sync,
        <T as FromRequest>::Future: Sync + Send,
        R: Future + 'static + Send + Sync,
        R::Output: Responder + 'static,
        E: Eq + Hash + Debug + Clone + Display,
    {
        let event: Event = event.into();
        if self.service_map.contains_key(&event) {
            log::error!("Duplicate Event: {:?}", &event);
        }

        Arc::get_mut(&mut self.service_map)
            .unwrap()
            .insert(event, factory(HandlerService::new(handler)));
        self
    }

    pub fn events(&self) -> Vec<Event> {
        self.service_map
            .keys()
            .map(|key| key.clone())
            .collect::<Vec<_>>()
    }
}

#[derive(Debug)]
pub struct ModuleRequest {
    inner: EventRequest,
    payload: Payload,
}

impl ModuleRequest {
    pub fn new<E>(event: E) -> Self
    where
        E: Into<Event>,
    {
        Self {
            inner: EventRequest::new(event),
            payload: Payload::None,
        }
    }

    pub fn payload(mut self, payload: Payload) -> Self {
        self.payload = payload;
        self
    }

    pub(crate) fn id(&self) -> &str { &self.inner.id }

    pub(crate) fn event(&self) -> &Event { &self.inner.event }
}

impl std::convert::Into<ServiceRequest> for ModuleRequest {
    fn into(self) -> ServiceRequest { ServiceRequest::new(self.inner, self.payload) }
}

impl ServiceFactory<ModuleRequest> for Module {
    type Response = EventResponse;
    type Error = SystemError;
    type Service = BoxService<ModuleRequest, Self::Response, Self::Error>;
    type Context = ();
    type Future = BoxFuture<'static, Result<Self::Service, Self::Error>>;

    fn new_service(&self, _cfg: Self::Context) -> Self::Future {
        let service_map = self.service_map.clone();
        Box::pin(async move {
            let service = ModuleService { service_map };
            let module_service = Box::new(service) as Self::Service;
            Ok(module_service)
        })
    }
}

pub struct ModuleService {
    service_map: Arc<HashMap<Event, EventServiceFactory>>,
}

impl Service<ModuleRequest> for ModuleService {
    type Response = EventResponse;
    type Error = SystemError;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn call(&self, request: ModuleRequest) -> Self::Future {
        log::trace!("Call module service for request {}", &request.id());
        match self.service_map.get(&request.event()) {
            Some(factory) => {
                let service_fut = factory.new_service(());
                let fut = ModuleServiceFuture {
                    fut: Box::pin(async {
                        let service = service_fut.await?;
                        service.call(request.into()).await
                    }),
                };
                Box::pin(async move { Ok(fut.await.unwrap_or_else(|e| e.into())) })
            },
            None => Box::pin(async { Err(InternalError::new("".to_string()).into()) }),
        }
    }
}

// type BoxModuleService = BoxService<ServiceRequest, ServiceResponse,
// SystemError>;

#[pin_project]
pub struct ModuleServiceFuture {
    #[pin]
    fut: BoxFuture<'static, Result<ServiceResponse, SystemError>>,
}

impl Future for ModuleServiceFuture {
    type Output = Result<EventResponse, SystemError>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            let (_, response) = ready!(self.as_mut().project().fut.poll(cx))?.into_parts();
            return Poll::Ready(Ok(response));
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
