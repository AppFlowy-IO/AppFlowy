use crate::{
    data::container::DataContainer,
    error::SystemError,
    module::ModuleData,
    request::FromRequest,
    response::Responder,
    service::{BoxService, Handler, Service, ServiceFactory, ServiceRequest, ServiceResponse},
};

use crate::{
    request::{payload::Payload, FlowyRequest},
    response::{FlowyResponse, FlowyResponseBuilder},
    service::{factory, BoxServiceFactory, HandlerService},
};
use futures_core::{future::LocalBoxFuture, ready};
use pin_project::pin_project;
use std::{
    cell::RefCell,
    collections::HashMap,
    fmt::Debug,
    future::Future,
    hash::Hash,
    marker::PhantomData,
    pin::Pin,
    rc::Rc,
    sync::Arc,
    task::{Context, Poll},
};
use tokio::sync::{
    mpsc,
    mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender},
};

pub type Command = String;
pub type CommandServiceFactory = BoxServiceFactory<(), ServiceRequest, ServiceResponse, SystemError>;

pub struct Module {
    name: String,
    data: DataContainer,
    factory_map: HashMap<Command, CommandServiceFactory>,
    req_tx: UnboundedSender<FlowyRequest>,
    req_rx: UnboundedReceiver<FlowyRequest>,
    resp_tx: UnboundedSender<FlowyResponse>,
}

impl Module {
    pub fn new(resp_tx: UnboundedSender<FlowyResponse>) -> Self {
        let (req_tx, req_rx) = unbounded_channel::<FlowyRequest>();
        Self {
            name: "".to_owned(),
            data: DataContainer::new(),
            factory_map: HashMap::new(),
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
        self.factory_map.insert(command, factory(HandlerService::new(handler)));
        self
    }

    pub fn can_handle(&self, cmd: &Command) -> bool { self.factory_map.contains_key(cmd) }

    pub fn req_tx(&self) -> UnboundedSender<FlowyRequest> { self.req_tx.clone() }

    pub fn handle(&self, request: FlowyRequest) {
        match self.req_tx.send(request) {
            Ok(_) => {},
            Err(e) => {
                log::error!("{:?}", e);
            },
        }
    }
}

impl Future for Module {
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.req_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(request) => match self.factory_map.get(request.get_cmd()) {
                    Some(factory) => {
                        let fut = ModuleServiceFuture {
                            request,
                            fut: factory.new_service(()),
                        };
                        let resp_tx = self.resp_tx.clone();
                        tokio::task::spawn_local(async move {
                            let resp = fut.await.unwrap_or_else(|e| panic!());
                            if let Err(e) = resp_tx.send(resp) {
                                log::error!("{:?}", e);
                            }
                        });
                    },
                    None => {
                        log::error!("Command: {} handler not found", request.get_cmd());
                    },
                },
            }
        }
    }
}

type BoxModuleService = BoxService<ServiceRequest, ServiceResponse, SystemError>;
#[pin_project]
pub struct ModuleServiceFuture {
    request: FlowyRequest,
    #[pin]
    fut: LocalBoxFuture<'static, Result<BoxModuleService, SystemError>>,
}

impl Future for ModuleServiceFuture {
    type Output = Result<FlowyResponse, SystemError>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            let service = ready!(self.as_mut().project().fut.poll(cx))?;
            let req = ServiceRequest::new(self.as_mut().request.clone(), Payload::None);
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

    pub async fn hello_service() -> String {
        println!("no params");
        "hello".to_string()
    }

    // #[tokio::test]

    #[test]
    fn test() {
        let mut runtime = Runtime::new().unwrap();
        runtime.block_on(async {
            let (resp_tx, mut resp_rx) = unbounded_channel::<FlowyResponse>();
            let command = "hello".to_string();
            let mut module = Module::new(resp_tx).event(command.clone(), hello_service);
            assert_eq!(module.can_handle(&command), true);
            let req_tx = module.req_tx();
            let mut event = async move {
                let request = FlowyRequest::new(command.clone());
                req_tx.send(request).unwrap();

                match resp_rx.recv().await {
                    Some(resp) => {
                        println!("{}", resp);
                    },
                    None => panic!(""),
                }
            };

            pin_mut!(module, event);
            future::select(module, event).await;
        });
    }
}
