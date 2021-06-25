use crate::{
    data::container::DataContainer,
    error::SystemError,
    module::ModuleData,
    request::FromRequest,
    response::Responder,
    service::{BoxService, Handler, Service, ServiceFactory, ServiceRequest, ServiceResponse},
};

use futures_core::{future::LocalBoxFuture, ready};
use std::{
    collections::HashMap,
    future::Future,
    hash::Hash,
    marker::PhantomData,
    pin::Pin,
    rc::Rc,
    task::{Context, Poll},
};
use tokio::sync::{mpsc, mpsc::UnboundedReceiver};

use crate::{
    request::{payload::Payload, FlowyRequest},
    service::{factory, BoxServiceFactory, HandlerService},
};
use pin_project::pin_project;
use std::fmt::Debug;

pub type Command = String;
pub type ModuleServiceFactory = BoxServiceFactory<(), ServiceRequest, ServiceResponse, SystemError>;

#[pin_project::pin_project]
pub struct Module {
    name: String,
    data: DataContainer,
    fact_map: HashMap<Command, ModuleServiceFactory>,
    cmd_rx: UnboundedReceiver<FlowyRequest>,
}

impl Module {
    pub fn new(cmd_rx: UnboundedReceiver<FlowyRequest>) -> Self {
        Self {
            name: "".to_owned(),
            data: DataContainer::new(),
            fact_map: HashMap::new(),
            cmd_rx,
        }
    }

    pub fn name(mut self, s: &str) -> Self {
        self.name = s.to_owned();
        self
    }

    pub fn data<D: 'static>(mut self, data: D) -> Self {
        let module_data = ModuleData::new(data);
        self.data.insert(module_data);
        self
    }

    pub fn event<H, T, R>(mut self, command: Command, handler: H) -> Self
    where
        H: Handler<T, R>,
        T: FromRequest + 'static,
        R: Future + 'static,
        R::Output: Responder + 'static,
    {
        self.fact_map.insert(command, factory(HandlerService::new(handler)));
        self
    }
}

impl Future for Module {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.cmd_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(request) => match self.fact_map.get(request.get_id()) {
                    Some(factory) => {
                        let service_future = factory.new_service(());
                        tokio::task::spawn_local(ModuleServiceFuture {
                            request,
                            service_future,
                        });
                    },
                    None => {},
                },
            }
        }
    }
}

#[pin_project(project = HandlerServiceProj)]
pub struct ModuleServiceFuture<Service, Error> {
    request: FlowyRequest,
    #[pin]
    service_future: LocalBoxFuture<'static, Result<Service, Error>>,
}

impl<Service, Error> Future for ModuleServiceFuture<Service, Error> {
    type Output = ();

    fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> { unimplemented!() }
}

impl ServiceFactory<ServiceRequest> for Module {
    type Response = ServiceResponse;
    type Error = SystemError;
    type Service = BoxService<ServiceRequest, ServiceResponse, SystemError>;
    type Config = ();
    type Future = LocalBoxFuture<'static, Result<Self::Service, Self::Error>>;

    fn new_service(&self, cfg: Self::Config) -> Self::Future { unimplemented!() }
}
