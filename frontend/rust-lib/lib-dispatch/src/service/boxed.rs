use crate::prelude::{AFBoxFuture, AFConcurrent};
use crate::service::{AFPluginServiceFactory, Service};

pub fn factory<SF, Req>(factory: SF) -> BoxServiceFactory<SF::Context, Req, SF::Response, SF::Error>
where
  SF: AFPluginServiceFactory<Req> + 'static + AFConcurrent,
  Req: 'static,
  SF::Response: 'static,
  SF::Service: 'static,
  SF::Future: 'static,
  SF::Error: 'static,
  <SF as AFPluginServiceFactory<Req>>::Service: AFConcurrent,
  <<SF as AFPluginServiceFactory<Req>>::Service as Service<Req>>::Future: AFConcurrent,
  <SF as AFPluginServiceFactory<Req>>::Future: AFConcurrent,
{
  BoxServiceFactory(Box::new(FactoryWrapper(factory)))
}

#[cfg(feature = "local_set")]
type Inner<Cfg, Req, Res, Err> = Box<
  dyn AFPluginServiceFactory<
    Req,
    Context = Cfg,
    Response = Res,
    Error = Err,
    Service = BoxService<Req, Res, Err>,
    Future = AFBoxFuture<'static, Result<BoxService<Req, Res, Err>, Err>>,
  >,
>;
#[cfg(not(feature = "local_set"))]
type Inner<Cfg, Req, Res, Err> = Box<
  dyn AFPluginServiceFactory<
      Req,
      Context = Cfg,
      Response = Res,
      Error = Err,
      Service = BoxService<Req, Res, Err>,
      Future = AFBoxFuture<'static, Result<BoxService<Req, Res, Err>, Err>>,
    > + Send
    + Sync,
>;

pub struct BoxServiceFactory<Cfg, Req, Res, Err>(Inner<Cfg, Req, Res, Err>);
impl<Cfg, Req, Res, Err> AFPluginServiceFactory<Req> for BoxServiceFactory<Cfg, Req, Res, Err>
where
  Req: 'static,
  Res: 'static,
  Err: 'static,
{
  type Response = Res;
  type Error = Err;
  type Service = BoxService<Req, Res, Err>;
  type Context = Cfg;
  type Future = AFBoxFuture<'static, Result<Self::Service, Self::Error>>;

  fn new_service(&self, cfg: Cfg) -> Self::Future {
    self.0.new_service(cfg)
  }
}

#[cfg(feature = "local_set")]
pub type BoxService<Req, Res, Err> = Box<
  dyn Service<Req, Response = Res, Error = Err, Future = AFBoxFuture<'static, Result<Res, Err>>>,
>;

#[cfg(not(feature = "local_set"))]
pub type BoxService<Req, Res, Err> = Box<
  dyn Service<Req, Response = Res, Error = Err, Future = AFBoxFuture<'static, Result<Res, Err>>>
    + Sync
    + Send,
>;

// #[allow(dead_code)]
// pub fn service<S, Req>(service: S) -> BoxService<Req, S::Response, S::Error>
// where
//     S: Service<Req> + 'static,
//     Req: 'static,
//     S::Future: 'static,
// {
//     Box::new(ServiceWrapper::new(service))
// }

impl<S, Req> Service<Req> for Box<S>
where
  S: Service<Req> + ?Sized,
{
  type Response = S::Response;
  type Error = S::Error;
  type Future = S::Future;

  fn call(&self, request: Req) -> S::Future {
    (**self).call(request)
  }
}

struct ServiceWrapper<S> {
  inner: S,
}

impl<S> ServiceWrapper<S> {
  fn new(inner: S) -> Self {
    Self { inner }
  }
}

impl<S, Req, Res, Err> Service<Req> for ServiceWrapper<S>
where
  S: Service<Req, Response = Res, Error = Err>,
  S::Future: 'static + AFConcurrent,
{
  type Response = Res;
  type Error = Err;
  type Future = AFBoxFuture<'static, Result<Res, Err>>;

  fn call(&self, req: Req) -> Self::Future {
    Box::pin(self.inner.call(req))
  }
}

struct FactoryWrapper<SF>(SF);

impl<SF, Req, Cfg, Res, Err> AFPluginServiceFactory<Req> for FactoryWrapper<SF>
where
  Req: 'static,
  Res: 'static,
  Err: 'static,
  SF: AFPluginServiceFactory<Req, Context = Cfg, Response = Res, Error = Err>,
  SF::Future: 'static,
  SF::Service: 'static + AFConcurrent,
  <<SF as AFPluginServiceFactory<Req>>::Service as Service<Req>>::Future: AFConcurrent + 'static,
  <SF as AFPluginServiceFactory<Req>>::Future: AFConcurrent,
{
  type Response = Res;
  type Error = Err;
  type Service = BoxService<Req, Res, Err>;
  type Context = Cfg;
  type Future = AFBoxFuture<'static, Result<Self::Service, Self::Error>>;

  fn new_service(&self, cfg: Cfg) -> Self::Future {
    let f = self.0.new_service(cfg);
    Box::pin(async {
      f.await
        .map(|s| Box::new(ServiceWrapper::new(s)) as Self::Service)
    })
  }
}
