use crate::{
    error::{Error, InternalError, SystemError},
    module::{as_module_map, Event, Module, ModuleMap, ModuleRequest},
    request::Payload,
    response::EventResponse,
    service::{Service, ServiceFactory},
    util::tokio_default_runtime,
};
use derivative::*;
use futures_core::future::BoxFuture;
use lazy_static::lazy_static;
use std::{
    fmt::{Debug, Display},
    hash::Hash,
    sync::RwLock,
};

lazy_static! {
    pub static ref EVENT_DISPATCH: RwLock<Option<EventDispatch>> = RwLock::new(None);
}

pub struct EventDispatch {
    module_map: ModuleMap,
    runtime: tokio::runtime::Runtime,
}

impl EventDispatch {
    pub fn construct<F>(module_factory: F)
    where
        F: FnOnce() -> Vec<Module>,
    {
        let modules = module_factory();
        let module_map = as_module_map(modules);
        let runtime = tokio_default_runtime().unwrap();

        let dispatch = EventDispatch {
            module_map,
            runtime,
        };

        *(EVENT_DISPATCH.write().unwrap()) = Some(dispatch);
    }

    pub async fn async_send<T>(request: DispatchRequest<T>) -> Result<EventResponse, SystemError>
    where
        T: 'static + Debug + Send + Sync,
    {
        match EVENT_DISPATCH.read() {
            Ok(dispatch) => {
                let dispatch = dispatch.as_ref().unwrap();
                let module_map = dispatch.module_map.clone();
                let service = Box::new(DispatchService { module_map });
                dispatch
                    .runtime
                    .spawn(async move { service.call(request).await })
                    .await
                    .unwrap_or_else(|e| {
                        let msg = format!("{:?}", e);
                        Ok(InternalError::new(msg).as_response())
                    })
            },

            Err(e) => {
                let msg = format!("{:?}", e);
                Err(InternalError::new(msg).into())
            },
        }
    }

    pub fn sync_send<T>(request: DispatchRequest<T>) -> Result<EventResponse, SystemError>
    where
        T: 'static + Debug + Send + Sync,
    {
        futures::executor::block_on(async { EventDispatch::async_send(request).await })
    }
}

pub type BoxStreamCallback<T> = Box<dyn FnOnce(T, EventResponse) + 'static + Send + Sync>;

#[derive(Derivative)]
#[derivative(Debug)]
pub struct DispatchRequest<T>
where
    T: 'static + Debug,
{
    pub config: T,
    pub event: Event,
    pub payload: Option<Payload>,
    #[derivative(Debug = "ignore")]
    pub callback: Option<BoxStreamCallback<T>>,
}

impl<T> DispatchRequest<T>
where
    T: 'static + Debug,
{
    pub fn new<E>(config: T, event: E) -> Self
    where
        E: Eq + Hash + Debug + Clone + Display,
    {
        Self {
            config,
            payload: None,
            event: event.into(),
            callback: None,
        }
    }

    pub fn payload(mut self, payload: Payload) -> Self {
        self.payload = Some(payload);
        self
    }

    pub fn callback<F>(mut self, callback: F) -> Self
    where
        F: FnOnce(T, EventResponse) + 'static + Send + Sync,
    {
        self.callback = Some(Box::new(callback));
        self
    }
}

pub(crate) struct DispatchService {
    pub(crate) module_map: ModuleMap,
}

impl<T> Service<DispatchRequest<T>> for DispatchService
where
    T: 'static + Debug + Send + Sync,
{
    type Response = EventResponse;
    type Error = SystemError;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn call(&self, dispatch_request: DispatchRequest<T>) -> Self::Future {
        let module_map = self.module_map.clone();
        let DispatchRequest {
            config,
            event,
            payload,
            callback,
        } = dispatch_request;

        let mut request = ModuleRequest::new(event.clone());
        if let Some(payload) = payload {
            request = request.payload(payload);
        };
        Box::pin(async move {
            let result = {
                match module_map.get(&event) {
                    Some(module) => {
                        let fut = module.new_service(());
                        let service_fut = fut.await?.call(request);
                        service_fut.await
                    },
                    None => {
                        let msg = format!(
                            "Can not find the module to handle the request:{:?}",
                            request
                        );
                        Err(InternalError::new(msg).into())
                    },
                }
            };

            let response = result.unwrap_or_else(|e| e.into());
            if let Some(callback) = callback {
                callback(config, response.clone());
            }

            Ok(response)
        })
    }
}
