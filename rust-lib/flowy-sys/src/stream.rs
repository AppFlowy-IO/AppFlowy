use crate::{
    error::{InternalError, SystemError},
    request::EventRequest,
    response::EventResponse,
    service::{BoxService, Service, ServiceFactory},
    system::ModuleMap,
};
use futures_core::{future::LocalBoxFuture, ready, task::Context};
use std::future::Future;
use tokio::{
    macros::support::{Pin, Poll},
    sync::mpsc::{unbounded_channel, UnboundedReceiver, UnboundedSender},
};

macro_rules! service_factor_impl {
    ($name:ident) => {
        #[allow(non_snake_case, missing_docs)]
        impl<T> ServiceFactory<CommandData<T>> for $name<T>
        where
            T: 'static,
        {
            type Response = EventResponse;
            type Error = SystemError;
            type Service = BoxService<CommandData<T>, Self::Response, Self::Error>;
            type Config = ();
            type Future = LocalBoxFuture<'static, Result<Self::Service, Self::Error>>;

            fn new_service(&self, _cfg: Self::Config) -> Self::Future {
                let module_map = self.module_map.clone();
                let service = Box::new(CommandSenderService { module_map });
                Box::pin(async move { Ok(service as Self::Service) })
            }
        }
    };
}

struct CommandSenderService {
    module_map: ModuleMap,
}

impl<T> Service<CommandData<T>> for CommandSenderService
where
    T: 'static,
{
    type Response = EventResponse;
    type Error = SystemError;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn call(&self, mut data: CommandData<T>) -> Self::Future {
        let module_map = self.module_map.clone();
        let request = data.request.take().unwrap();
        let fut = async move {
            let result = {
                match module_map.get(request.get_event()) {
                    Some(module) => {
                        let config = request.get_id().to_owned();
                        let fut = module.new_service(config);
                        let service_fut = fut.await?.call(request);
                        service_fut.await
                    },
                    None => {
                        let msg = format!("Can not find the module to handle the request:{:?}", request);
                        Err(InternalError::new(msg).into())
                    },
                }
            };

            let response = result.unwrap_or_else(|e| e.into());
            if let Some(callback) = data.callback {
                callback(data.config, response.clone());
            }

            Ok(response)
        };
        Box::pin(fut)
    }
}

pub type BoxStreamCallback<T> = Box<dyn FnOnce(T, EventResponse) + 'static + Send + Sync>;
pub struct CommandData<T>
where
    T: 'static,
{
    config: T,
    request: Option<EventRequest>,
    callback: Option<BoxStreamCallback<T>>,
}

impl<T> CommandData<T> {
    pub fn new(config: T, request: Option<EventRequest>) -> Self {
        Self {
            config,
            request,
            callback: None,
        }
    }

    pub fn with_callback(mut self, callback: BoxStreamCallback<T>) -> Self {
        self.callback = Some(callback);
        self
    }
}

pub struct CommandSender<T>
where
    T: 'static,
{
    module_map: ModuleMap,
    data_tx: UnboundedSender<CommandData<T>>,
    data_rx: Option<UnboundedReceiver<CommandData<T>>>,
}

service_factor_impl!(CommandSender);

impl<T> CommandSender<T>
where
    T: 'static,
{
    pub fn new(module_map: ModuleMap) -> Self {
        let (data_tx, data_rx) = unbounded_channel::<CommandData<T>>();
        Self {
            module_map,
            data_tx,
            data_rx: Some(data_rx),
        }
    }

    pub fn async_send(&self, data: CommandData<T>) { let _ = self.data_tx.send(data); }

    pub fn sync_send(&self, data: CommandData<T>) -> EventResponse {
        let factory = self.new_service(());

        futures::executor::block_on(async {
            let service = factory.await.unwrap();
            service.call(data).await.unwrap()
        })
    }

    pub fn tx(&self) -> UnboundedSender<CommandData<T>> { self.data_tx.clone() }

    pub fn take_data_rx(&mut self) -> UnboundedReceiver<CommandData<T>> { self.data_rx.take().unwrap() }
}

pub struct CommandSenderRunner<T>
where
    T: 'static,
{
    module_map: ModuleMap,
    data_rx: UnboundedReceiver<CommandData<T>>,
}

service_factor_impl!(CommandSenderRunner);

impl<T> CommandSenderRunner<T>
where
    T: 'static,
{
    pub fn new(module_map: ModuleMap, data_rx: UnboundedReceiver<CommandData<T>>) -> Self {
        Self { module_map, data_rx }
    }
}

impl<T> Future for CommandSenderRunner<T>
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
