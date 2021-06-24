use crate::{
    error::Error,
    payload::Payload,
    request::FlowyRequest,
    response::{FlowyResponse, Responder},
    service::{Service, ServiceFactory, ServiceRequest, ServiceResponse},
    util::ready::*,
};
use futures_core::ready;
use paste::paste;
use pin_project::pin_project;
use std::{
    future::Future,
    marker::PhantomData,
    pin::Pin,
    task::{Context, Poll},
};

use futures_core::future::LocalBoxFuture;

pub fn factory<SF, Req>(factory: SF) -> BoxServiceFactory<SF::Config, Req, SF::Response, SF::Error, SF::InitError>
where
    SF: ServiceFactory<Req> + 'static,
    Req: 'static,
    SF::Response: 'static,
    SF::Service: 'static,
    SF::Future: 'static,
    SF::Error: 'static,
    SF::InitError: 'static,
{
    BoxServiceFactory(Box::new(FactoryWrapper(factory)))
}

pub struct BoxServiceFactory<Cfg, Req, Res, Err, InitErr>(Inner<Cfg, Req, Res, Err, InitErr>);
impl<C, Req, Res, Err, InitErr> ServiceFactory<Req> for BoxServiceFactory<C, Req, Res, Err, InitErr>
where
    Req: 'static,
    Res: 'static,
    Err: 'static,
    InitErr: 'static,
{
    type Response = Res;
    type Error = Err;
    type Service = BoxService<Req, Res, Err>;
    type InitError = InitErr;
    type Config = C;
    type Future = LocalBoxFuture<'static, Result<Self::Service, InitErr>>;

    fn new_service(&self, cfg: C) -> Self::Future { self.0.new_service(cfg) }
}

type Inner<C, Req, Res, Err, InitErr> = Box<
    dyn ServiceFactory<
        Req,
        Config = C,
        Response = Res,
        Error = Err,
        InitError = InitErr,
        Service = BoxService<Req, Res, Err>,
        Future = LocalBoxFuture<'static, Result<BoxService<Req, Res, Err>, InitErr>>,
    >,
>;

pub type BoxService<Req, Res, Err> =
    Box<dyn Service<Req, Response = Res, Error = Err, Future = LocalBoxFuture<'static, Result<Res, Err>>>>;

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

impl<SF, Req, Cfg, Res, Err, InitErr> ServiceFactory<Req> for FactoryWrapper<SF>
where
    Req: 'static,
    Res: 'static,
    Err: 'static,
    InitErr: 'static,
    SF: ServiceFactory<Req, Config = Cfg, Response = Res, Error = Err, InitError = InitErr>,
    SF::Future: 'static,
    SF::Service: 'static,
    <SF::Service as Service<Req>>::Future: 'static,
{
    type Response = Res;
    type Error = Err;
    type Service = BoxService<Req, Res, Err>;
    type InitError = InitErr;
    type Config = Cfg;
    type Future = LocalBoxFuture<'static, Result<Self::Service, Self::InitError>>;

    fn new_service(&self, cfg: Cfg) -> Self::Future {
        let f = self.0.new_service(cfg);
        Box::pin(async { f.await.map(|s| Box::new(ServiceWrapper::new(s)) as _) })
    }
}
