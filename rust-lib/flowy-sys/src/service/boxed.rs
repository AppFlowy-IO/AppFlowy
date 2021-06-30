use crate::service::{Service, ServiceFactory};
use futures_core::future::LocalBoxFuture;

pub fn factory<SF, Req>(factory: SF) -> BoxServiceFactory<SF::Context, Req, SF::Response, SF::Error>
where
    SF: ServiceFactory<Req> + 'static,
    Req: 'static,
    SF::Response: 'static,
    SF::Service: 'static,
    SF::Future: 'static,
    SF::Error: 'static,
{
    BoxServiceFactory(Box::new(FactoryWrapper(factory)))
}

type Inner<Cfg, Req, Res, Err> = Box<
    dyn ServiceFactory<
        Req,
        Context = Cfg,
        Response = Res,
        Error = Err,
        Service = BoxService<Req, Res, Err>,
        Future = LocalBoxFuture<'static, Result<BoxService<Req, Res, Err>, Err>>,
    >,
>;

pub struct BoxServiceFactory<Cfg, Req, Res, Err>(Inner<Cfg, Req, Res, Err>);
impl<Cfg, Req, Res, Err> ServiceFactory<Req> for BoxServiceFactory<Cfg, Req, Res, Err>
where
    Req: 'static,
    Res: 'static,
    Err: 'static,
{
    type Response = Res;
    type Error = Err;
    type Service = BoxService<Req, Res, Err>;
    type Context = Cfg;
    type Future = LocalBoxFuture<'static, Result<Self::Service, Self::Error>>;

    fn new_service(&self, cfg: Cfg) -> Self::Future { self.0.new_service(cfg) }
}

pub type BoxService<Req, Res, Err> =
    Box<dyn Service<Req, Response = Res, Error = Err, Future = LocalBoxFuture<'static, Result<Res, Err>>>>;

#[allow(dead_code)]
pub fn service<S, Req>(service: S) -> BoxService<Req, S::Response, S::Error>
where
    S: Service<Req> + 'static,
    Req: 'static,
    S::Future: 'static,
{
    Box::new(ServiceWrapper::new(service))
}

impl<S, Req> Service<Req> for Box<S>
where
    S: Service<Req> + ?Sized,
{
    type Response = S::Response;
    type Error = S::Error;
    type Future = S::Future;

    fn call(&self, request: Req) -> S::Future { (**self).call(request) }
}

struct ServiceWrapper<S> {
    inner: S,
}

impl<S> ServiceWrapper<S> {
    fn new(inner: S) -> Self { Self { inner } }
}

impl<S, Req, Res, Err> Service<Req> for ServiceWrapper<S>
where
    S: Service<Req, Response = Res, Error = Err>,
    S::Future: 'static,
{
    type Response = Res;
    type Error = Err;
    type Future = LocalBoxFuture<'static, Result<Res, Err>>;

    fn call(&self, req: Req) -> Self::Future { Box::pin(self.inner.call(req)) }
}

struct FactoryWrapper<SF>(SF);

impl<SF, Req, Cfg, Res, Err> ServiceFactory<Req> for FactoryWrapper<SF>
where
    Req: 'static,
    Res: 'static,
    Err: 'static,
    SF: ServiceFactory<Req, Context = Cfg, Response = Res, Error = Err>,
    SF::Future: 'static,
    SF::Service: 'static,
    <SF::Service as Service<Req>>::Future: 'static,
{
    type Response = Res;
    type Error = Err;
    type Service = BoxService<Req, Res, Err>;
    type Context = Cfg;
    type Future = LocalBoxFuture<'static, Result<Self::Service, Self::Error>>;

    fn new_service(&self, cfg: Cfg) -> Self::Future {
        let f = self.0.new_service(cfg);
        Box::pin(async { f.await.map(|s| Box::new(ServiceWrapper::new(s)) as Self::Service) })
    }
}
