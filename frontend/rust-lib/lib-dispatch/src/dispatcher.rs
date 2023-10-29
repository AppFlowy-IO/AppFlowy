use std::any::Any;
use std::{future::Future, sync::Arc};

use derivative::*;

use crate::module::AFPluginStateMap;
use crate::runtime::AFPluginRuntime;
use crate::{
  errors::{DispatchError, Error, InternalError},
  module::{as_plugin_map, AFPlugin, AFPluginMap, AFPluginRequest},
  response::AFPluginEventResponse,
  service::{AFPluginServiceFactory, Service},
};

#[cfg(feature = "single_thread")]
pub trait AFConcurrent {}

#[cfg(feature = "single_thread")]
impl<T> AFConcurrent for T where T: ?Sized {}

#[cfg(not(feature = "single_thread"))]
pub trait AFConcurrent: Send + Sync {}

#[cfg(not(feature = "single_thread"))]
impl<T> AFConcurrent for T where T: Send + Sync {}

#[cfg(feature = "single_thread")]
pub type AFBoxFuture<'a, T> = futures_core::future::LocalBoxFuture<'a, T>;

#[cfg(not(feature = "single_thread"))]
pub type AFBoxFuture<'a, T> = futures_core::future::BoxFuture<'a, T>;

pub type AFStateMap = std::sync::Arc<AFPluginStateMap>;

#[cfg(feature = "single_thread")]
pub(crate) fn downcast_owned<T: 'static>(boxed: AFBox) -> Option<T> {
  boxed.downcast().ok().map(|boxed| *boxed)
}

#[cfg(not(feature = "single_thread"))]
pub(crate) fn downcast_owned<T: 'static + Send + Sync>(boxed: AFBox) -> Option<T> {
  boxed.downcast().ok().map(|boxed| *boxed)
}

#[cfg(feature = "single_thread")]
pub(crate) type AFBox = Box<dyn Any>;

#[cfg(not(feature = "single_thread"))]
pub(crate) type AFBox = Box<dyn Any + Send + Sync>;

#[cfg(feature = "single_thread")]
pub type BoxFutureCallback =
  Box<dyn FnOnce(AFPluginEventResponse) -> AFBoxFuture<'static, ()> + 'static>;

#[cfg(not(feature = "single_thread"))]
pub type BoxFutureCallback =
  Box<dyn FnOnce(AFPluginEventResponse) -> AFBoxFuture<'static, ()> + Send + Sync + 'static>;

pub struct AFPluginDispatcher {
  plugins: AFPluginMap,
  runtime: Arc<AFPluginRuntime>,
}

impl AFPluginDispatcher {
  pub fn construct<F>(runtime: Arc<AFPluginRuntime>, module_factory: F) -> AFPluginDispatcher
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

  pub async fn async_send<Req>(
    dispatch: Arc<AFPluginDispatcher>,
    request: Req,
  ) -> AFPluginEventResponse
  where
    Req: Into<AFPluginRequest>,
  {
    AFPluginDispatcher::async_send_with_callback(dispatch, request, |_| Box::pin(async {})).await
  }

  pub async fn async_send_with_callback<Req, Callback>(
    dispatch: Arc<AFPluginDispatcher>,
    request: Req,
    callback: Callback,
  ) -> AFPluginEventResponse
  where
    Req: Into<AFPluginRequest>,
    Callback: FnOnce(AFPluginEventResponse) -> AFBoxFuture<'static, ()> + AFConcurrent + 'static,
  {
    let request: AFPluginRequest = request.into();
    let plugins = dispatch.plugins.clone();
    let service = Box::new(DispatchService { plugins });
    tracing::trace!("Async event: {:?}", &request.event);
    let service_ctx = DispatchContext {
      request,
      callback: Some(Box::new(callback)),
    };

    let handle = dispatch.runtime.spawn(async move {
      service.call(service_ctx).await.unwrap_or_else(|e| {
        tracing::error!("Dispatch runtime error: {:?}", e);
        InternalError::Other(format!("{:?}", e)).as_response()
      })
    });

    let result = dispatch.runtime.run_until(handle).await;
    result.unwrap_or_else(|e| {
      let msg = format!("EVENT_DISPATCH join error: {:?}", e);
      tracing::error!("{}", msg);
      let error = InternalError::JoinError(msg);
      error.as_response()
    })
  }

  #[cfg(not(feature = "single_thread"))]
  pub fn sync_send(
    dispatch: Arc<AFPluginDispatcher>,
    request: AFPluginRequest,
  ) -> AFPluginEventResponse {
    futures::executor::block_on(async {
      AFPluginDispatcher::async_send_with_callback(dispatch, request, |_| Box::pin(async {})).await
    })
  }

  #[cfg(feature = "single_thread")]
  pub fn spawn<F>(&self, f: F)
  where
    F: Future<Output = ()> + 'static,
  {
    self.runtime.spawn(f);
  }

  #[cfg(not(feature = "single_thread"))]
  pub fn spawn<F>(&self, f: F)
  where
    F: Future<Output = ()> + Send + 'static,
  {
    self.runtime.spawn(f);
  }
}

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
  type Response = AFPluginEventResponse;
  type Error = DispatchError;
  type Future = AFBoxFuture<'static, Result<Self::Response, Self::Error>>;

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
          },
          None => {
            let msg = format!("Can not find the event handler. {:?}", request);
            tracing::error!("{}", msg);
            Err(InternalError::HandleNotFound(msg).into())
          },
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
