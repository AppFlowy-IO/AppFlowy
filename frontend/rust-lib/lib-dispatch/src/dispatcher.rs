use crate::runtime::AFPluginRuntime;
use crate::{
    errors::{DispatchError, Error, InternalError},
    module::{as_plugin_map, AFPlugin, AFPluginMap, AFPluginRequest},
    response::EventResponse,
    service::{AFPluginServiceFactory, Service},
};
use derivative::*;
use futures_core::future::BoxFuture;
use futures_util::task::Context;
use pin_project::pin_project;
use std::{future::Future, sync::Arc};
use tokio::macros::support::{Pin, Poll};

pub struct AFPluginDispatcher {
    plugins: AFPluginMap,
    runtime: AFPluginRuntime,
}

impl AFPluginDispatcher {
    pub fn construct<F>(runtime: AFPluginRuntime, module_factory: F) -> AFPluginDispatcher
    where
        F: FnOnce() -> Vec<AFPlugin>,
    {
        let plugins = module_factory();
        tracing::trace!("{}", plugin_info(&plugins));
        AFPluginDispatcher {
            plugins: as_plugin_map(plugins),
            runtime,
        }
    }

    pub fn async_send<Req>(dispatch: Arc<AFPluginDispatcher>, request: Req) -> DispatchFuture<EventResponse>
    where
        Req: std::convert::Into<AFPluginRequest>,
    {
        AFPluginDispatcher::async_send_with_callback(dispatch, request, |_| Box::pin(async {}))
    }

    pub fn async_send_with_callback<Req, Callback>(
        dispatch: Arc<AFPluginDispatcher>,
        request: Req,
        callback: Callback,
    ) -> DispatchFuture<EventResponse>
    where
        Req: std::convert::Into<AFPluginRequest>,
        Callback: FnOnce(EventResponse) -> BoxFuture<'static, ()> + 'static + Send + Sync,
    {
        let request: AFPluginRequest = request.into();
        let plugins = dispatch.plugins.clone();
        let service = Box::new(DispatchService { plugins });
        tracing::trace!("Async event: {:?}", &request.event);
        let service_ctx = DispatchContext {
            request,
            callback: Some(Box::new(callback)),
        };
        let join_handle = dispatch.runtime.spawn(async move {
            service.call(service_ctx).await.unwrap_or_else(|e| {
                tracing::error!("Dispatch runtime error: {:?}", e);
                InternalError::Other(format!("{:?}", e)).as_response()
            })
        });

        DispatchFuture {
            fut: Box::pin(async move {
                join_handle.await.unwrap_or_else(|e| {
                    let msg = format!("EVENT_DISPATCH join error: {:?}", e);
                    tracing::error!("{}", msg);
                    let error = InternalError::JoinError(msg);
                    error.as_response()
                })
            }),
        }
    }

    pub fn sync_send(dispatch: Arc<AFPluginDispatcher>, request: AFPluginRequest) -> EventResponse {
        futures::executor::block_on(async {
            AFPluginDispatcher::async_send_with_callback(dispatch, request, |_| Box::pin(async {})).await
        })
    }

    pub fn spawn<F>(&self, f: F)
    where
        F: Future<Output = ()> + Send + 'static,
    {
        self.runtime.spawn(f);
    }
}

#[pin_project]
pub struct DispatchFuture<T: Send + Sync> {
    #[pin]
    pub fut: Pin<Box<dyn Future<Output = T> + Sync + Send>>,
}

impl<T> Future for DispatchFuture<T>
where
    T: Send + Sync,
{
    type Output = T;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let this = self.as_mut().project();
        Poll::Ready(futures_core::ready!(this.fut.poll(cx)))
    }
}

pub type BoxFutureCallback = Box<dyn FnOnce(EventResponse) -> BoxFuture<'static, ()> + 'static + Send + Sync>;

#[derive(Derivative)]
#[derivative(Debug)]
pub struct DispatchContext {
    pub request: AFPluginRequest,
    #[derivative(Debug = "ignore")]
    pub callback: Option<BoxFutureCallback>,
}

impl DispatchContext {
    pub(crate) fn into_parts(self) -> (AFPluginRequest, Option<BoxFutureCallback>) {
        let DispatchContext { request, callback } = self;
        (request, callback)
    }
}

pub(crate) struct DispatchService {
    pub(crate) plugins: AFPluginMap,
}

impl Service<DispatchContext> for DispatchService {
    type Response = EventResponse;
    type Error = DispatchError;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    #[cfg_attr(
        feature = "use_tracing",
        tracing::instrument(name = "DispatchService", level = "debug", skip(self, ctx))
    )]
    fn call(&self, ctx: DispatchContext) -> Self::Future {
        let module_map = self.plugins.clone();
        let (request, callback) = ctx.into_parts();

        Box::pin(async move {
            let result = {
                // print_module_map_info(&module_map);
                match module_map.get(&request.event) {
                    Some(module) => {
                        tracing::trace!("Handle event: {:?} by {:?}", &request.event, module.name);
                        let fut = module.new_service(());
                        let service_fut = fut.await?.call(request);
                        service_fut.await
                    }
                    None => {
                        let msg = format!("Can not find the event handler. {:?}", request);
                        tracing::error!("{}", msg);
                        Err(InternalError::HandleNotFound(msg).into())
                    }
                }
            };

            let response = result.unwrap_or_else(|e| e.into());
            tracing::trace!("Dispatch result: {:?}", response);
            if let Some(callback) = callback {
                callback(response.clone()).await;
            }

            Ok(response)
        })
    }
}

#[allow(dead_code)]
fn plugin_info(plugins: &[AFPlugin]) -> String {
    let mut info = format!("{} plugins loaded\n", plugins.len());
    for module in plugins {
        info.push_str(&format!("-> {} loaded \n", module.name));
    }
    info
}

#[allow(dead_code)]
fn print_plugins(plugins: &AFPluginMap) {
    plugins.iter().for_each(|(k, v)| {
        tracing::info!("Event: {:?} plugin : {:?}", k, v.name);
    })
}
