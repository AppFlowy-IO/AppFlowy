use crate::{
    error::{InternalError, SystemError},
    module::{Event, Module},
    request::EventRequest,
    response::EventResponse,
    service::{BoxService, Service, ServiceFactory},
    system::ModuleMap,
};
use futures_core::{future::LocalBoxFuture, ready, task::Context};
use std::{collections::HashMap, future::Future, rc::Rc};
use tokio::{
    macros::support::{Pin, Poll},
    sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender},
};

pub type BoxStreamCallback<T> = Box<dyn FnOnce(T, EventResponse) + 'static>;
pub struct StreamData<T>
where
    T: 'static,
{
    config: T,
    request: Option<EventRequest>,
    callback: BoxStreamCallback<T>,
}

impl<T> StreamData<T> {
    pub fn new(config: T, request: Option<EventRequest>, callback: BoxStreamCallback<T>) -> Self {
        Self {
            config,
            request,
            callback,
        }
    }
}

pub struct CommandStream<T>
where
    T: 'static,
{
    module_map: ModuleMap,
    pub data_tx: UnboundedSender<StreamData<T>>,
    data_rx: UnboundedReceiver<StreamData<T>>,
}

impl<T> CommandStream<T> {
    pub fn new(module_map: ModuleMap) -> Self {
        let (data_tx, data_rx) = unbounded_channel::<StreamData<T>>();
        Self {
            module_map,
            data_tx,
            data_rx,
        }
    }

    pub fn send(&self, data: StreamData<T>) { let _ = self.data_tx.send(data); }
}

impl<T> Future for CommandStream<T>
where
    T: 'static,
{
    type Output = ();
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match ready!(Pin::new(&mut self.data_rx).poll_recv(cx)) {
                None => return Poll::Ready(()),
                Some(ctx) => {
                    let factory = self.new_service(());
                    tokio::task::spawn_local(async move {
                        let service = factory.await.unwrap();
                        let _ = service.call(ctx).await;
                    });
                },
            }
        }
    }
}

impl<T> ServiceFactory<StreamData<T>> for CommandStream<T>
where
    T: 'static,
{
    type Response = ();
    type Error = SystemError;
    type Service = BoxService<StreamData<T>, Self::Response, Self::Error>;
    type Config = ();
    type Future = LocalBoxFuture<'static, Result<Self::Service, Self::Error>>;

    fn new_service(&self, _cfg: Self::Config) -> Self::Future {
        let module_map = self.module_map.clone();
        let service = Box::new(CommandStreamService { module_map });
        Box::pin(async move { Ok(service as Self::Service) })
    }
}

pub struct CommandStreamService {
    module_map: ModuleMap,
}

impl<T> Service<StreamData<T>> for CommandStreamService
where
    T: 'static,
{
    type Response = ();
    type Error = SystemError;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn call(&self, mut data: StreamData<T>) -> Self::Future {
        let module_map = self.module_map.clone();

        let fut = async move {
            let request = data.request.take().unwrap();
            let result = || async {
                match module_map.get(request.get_event()) {
                    Some(module) => {
                        let config = request.get_id().to_owned();
                        let fut = module.new_service(config);
                        let service_fut = fut.await?.call(request);
                        service_fut.await
                    },
                    None => Err(InternalError::new("".to_owned()).into()),
                }
            };

            let resp = result().await.unwrap();
            (data.callback)(data.config, resp);
            Ok(())
        };
        Box::pin(fut)
    }
}
