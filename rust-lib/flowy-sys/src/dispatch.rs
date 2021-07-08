use crate::{
    error::{Error, InternalError, SystemError},
    module::{as_module_map, Module, ModuleMap, ModuleRequest},
    response::EventResponse,
    service::{Service, ServiceFactory},
    util::tokio_default_runtime,
};
use derivative::*;
use futures_core::future::BoxFuture;
use futures_util::task::Context;
use lazy_static::lazy_static;
use pin_project::pin_project;
use std::{future::Future, sync::RwLock};
use tokio::macros::support::{Pin, Poll};

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
        log::debug!("{}", module_info(&modules));
        let module_map = as_module_map(modules);
        let runtime = tokio_default_runtime().unwrap();
        let dispatch = EventDispatch {
            module_map,
            runtime,
        };

        *(EVENT_DISPATCH.write().unwrap()) = Some(dispatch);
    }

    pub fn async_send<Req, Callback>(request: Req, callback: Callback) -> DispatchFuture
    where
        Req: std::convert::Into<ModuleRequest>,
        Callback: FnOnce(EventResponse) -> BoxFuture<'static, ()> + 'static + Send + Sync,
    {
        let request: ModuleRequest = request.into();
        match EVENT_DISPATCH.read() {
            Ok(dispatch) => {
                let dispatch = dispatch.as_ref().unwrap();
                let module_map = dispatch.module_map.clone();
                let service = Box::new(DispatchService { module_map });
                log::trace!(
                    "{}: dispatch {:?} to runtime",
                    &request.id(),
                    &request.event()
                );
                let service_ctx = DispatchContext {
                    request,
                    callback: Some(Box::new(callback)),
                };
                let join_handle = dispatch.runtime.spawn(async move {
                    service
                        .call(service_ctx)
                        .await
                        .unwrap_or_else(|e| InternalError::new(format!("{:?}", e)).as_response())
                });

                DispatchFuture {
                    fut: Box::pin(async move {
                        join_handle.await.unwrap_or_else(|e| {
                            InternalError::new(format!("Dispatch join error: {:?}", e))
                                .as_response()
                        })
                    }),
                }
            },

            Err(e) => {
                let msg = format!("Dispatch runtime error: {:?}", e);
                log::trace!("{}", msg);
                DispatchFuture {
                    fut: Box::pin(async { InternalError::new(msg).as_response() }),
                }
            },
        }
    }

    pub fn sync_send(request: ModuleRequest) -> EventResponse {
        futures::executor::block_on(async {
            EventDispatch::async_send(request, |response| {
                dbg!(&response);
                Box::pin(async {})
            })
            .await
        })
    }
}

#[pin_project]
pub struct DispatchFuture {
    #[pin]
    fut: BoxFuture<'static, EventResponse>,
}

impl Future for DispatchFuture {
    type Output = EventResponse;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let this = self.as_mut().project();
        loop {
            return Poll::Ready(futures_core::ready!(this.fut.poll(cx)));
        }
    }
}

pub type BoxFutureCallback =
    Box<dyn FnOnce(EventResponse) -> BoxFuture<'static, ()> + 'static + Send + Sync>;

#[derive(Derivative)]
#[derivative(Debug)]
pub struct DispatchContext {
    pub request: ModuleRequest,
    #[derivative(Debug = "ignore")]
    pub callback: Option<BoxFutureCallback>,
}

impl DispatchContext {
    pub(crate) fn into_parts(self) -> (ModuleRequest, Option<BoxFutureCallback>) {
        let DispatchContext { request, callback } = self;
        (request, callback)
    }
}

pub(crate) struct DispatchService {
    pub(crate) module_map: ModuleMap,
}

impl Service<DispatchContext> for DispatchService {
    type Response = EventResponse;
    type Error = SystemError;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    #[cfg_attr(
        feature = "use_tracing",
        tracing::instrument(name = "DispatchService", level = "debug", skip(self, ctx))
    )]
    fn call(&self, ctx: DispatchContext) -> Self::Future {
        let module_map = self.module_map.clone();
        let (request, callback) = ctx.into_parts();

        Box::pin(async move {
            let result = {
                match module_map.get(&request.event()) {
                    Some(module) => {
                        let fut = module.new_service(());
                        log::trace!(
                            "{}: handle event: {:?} by {}",
                            request.id(),
                            request.event(),
                            module.name
                        );
                        let service_fut = fut.await?.call(request);
                        service_fut.await
                    },
                    None => {
                        let msg = format!(
                            "Can not find the module to handle the request:{:?}",
                            request
                        );
                        log::trace!("{}", msg);
                        Err(InternalError::new(msg).into())
                    },
                }
            };

            let response = result.unwrap_or_else(|e| e.into());
            log::trace!("Dispatch result: {:?}", response);
            if let Some(callback) = callback {
                callback(response.clone()).await;
            }

            Ok(response)
        })
    }
}

fn module_info(modules: &Vec<Module>) -> String {
    let mut info = format!("{} modules loaded\n", modules.len());
    for module in modules {
        info.push_str(&format!("-> {} loaded \n", module.name));
    }
    info
}
