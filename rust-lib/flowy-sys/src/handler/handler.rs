use crate::error::Error;
use crate::payload::Payload;
use crate::request::FlowyRequest;
use crate::response::{FlowyResponse, Responder};
use crate::service::{Service, ServiceFactory, ServiceRequest, ServiceResponse};
use crate::util::ready::*;
use futures_core::ready;
use paste::paste;
use pin_project::pin_project;
use std::future::Future;
use std::marker::PhantomData;
use std::pin::Pin;
use std::task::{Context, Poll};

pub trait Handler<T, R>: Clone + 'static
where
    R: Future,
    R::Output: Responder,
{
    fn call(&self, param: T) -> R;
}

pub trait FromRequest: Sized {
    type Error: Into<Error>;
    type Future: Future<Output = Result<Self, Self::Error>>;

    fn from_request(req: &FlowyRequest, payload: &mut Payload) -> Self::Future;
}

pub struct HandlerService<H, T, R>
where
    H: Handler<T, R>,
    T: FromRequest,
    R: Future,
    R::Output: Responder,
{
    handler: H,
    _phantom: PhantomData<(T, R)>,
}

impl<H, T, R> HandlerService<H, T, R>
where
    H: Handler<T, R>,
    T: FromRequest,
    R: Future,
    R::Output: Responder,
{
    pub fn new(handler: H) -> Self {
        Self {
            handler,
            _phantom: PhantomData,
        }
    }
}

impl<H, T, R> Clone for HandlerService<H, T, R>
where
    H: Handler<T, R>,
    T: FromRequest,
    R: Future,
    R::Output: Responder,
{
    fn clone(&self) -> Self {
        Self {
            handler: self.handler.clone(),
            _phantom: PhantomData,
        }
    }
}

impl<F, T, R> ServiceFactory<ServiceRequest> for HandlerService<F, T, R>
where
    F: Handler<T, R>,
    T: FromRequest,
    R: Future,
    R::Output: Responder,
{
    type Response = ServiceResponse;
    type Error = Error;
    type Service = Self;
    type InitError = ();
    type Config = ();
    type Future = Ready<Result<Self::Service, ()>>;

    fn new_service(&self, _: ()) -> Self::Future {
        ready(Ok(self.clone()))
    }
}

/// HandlerService is both it's ServiceFactory and Service Type.
impl<H, T, R> Service<ServiceRequest> for HandlerService<H, T, R>
where
    H: Handler<T, R>,
    T: FromRequest,
    R: Future,
    R::Output: Responder,
{
    type Response = ServiceResponse;
    type Error = Error;
    type Future = HandlerServiceFuture<H, T, R>;

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let (req, mut payload) = req.into_parts();
        let fut = T::from_request(&req, &mut payload);
        HandlerServiceFuture::Extract(fut, Some(req), self.handler.clone())
    }
}

#[pin_project(project = HandlerServiceProj)]
pub enum HandlerServiceFuture<H, T, R>
where
    H: Handler<T, R>,
    T: FromRequest,
    R: Future,
    R::Output: Responder,
{
    Extract(#[pin] T::Future, Option<FlowyRequest>, H),
    Handle(#[pin] R, Option<FlowyRequest>),
}

impl<F, T, R> Future for HandlerServiceFuture<F, T, R>
where
    F: Handler<T, R>,
    T: FromRequest,
    R: Future,
    R::Output: Responder,
{
    // Error type in this future is a placeholder type.
    // all instances of error must be converted to ServiceResponse and return in Ok.
    type Output = Result<ServiceResponse, Error>;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        loop {
            match self.as_mut().project() {
                HandlerServiceProj::Extract(fut, req, handle) => {
                    match ready!(fut.poll(cx)) {
                        Ok(item) => {
                            let fut = handle.call(item);
                            let state = HandlerServiceFuture::Handle(fut, req.take());
                            self.as_mut().set(state);
                        }
                        Err(err) => {
                            let req = req.take().unwrap();
                            let res = FlowyResponse::from_error(err.into());
                            return Poll::Ready(Ok(ServiceResponse::new(req, res)));
                        }
                    };
                }
                HandlerServiceProj::Handle(fut, req) => {
                    let res = ready!(fut.poll(cx));
                    let req = req.take().unwrap();
                    let res = res.respond_to(&req);
                    return Poll::Ready(Ok(ServiceResponse::new(req, res)));
                }
            }
        }
    }
}

macro_rules! factory_tuple ({ $($param:ident)* } => {
    impl<Func, $($param,)* Res> Handler<($($param,)*), Res> for Func
    where Func: Fn($($param),*) -> Res + Clone + 'static,
          Res: Future,
          Res::Output: Responder,
    {
        #[allow(non_snake_case)]
        fn call(&self, ($($param,)*): ($($param,)*)) -> Res {
            (self)($($param,)*)
        }
    }
});

macro_rules! tuple_from_req ({$tuple_type:ident, $(($n:tt, $T:ident)),+} => {
    #[allow(non_snake_case)]
    mod $tuple_type {
        use super::*;

        #[pin_project::pin_project]
        struct FromRequestFutures<$($T: FromRequest),+>($(#[pin] $T::Future),+);

        /// FromRequest implementation for tuple
        #[doc(hidden)]
        #[allow(unused_parens)]
        impl<$($T: FromRequest + 'static),+> FromRequest for ($($T,)+)
        {
            type Error = Error;
            type Future = $tuple_type<$($T),+>;

            fn from_request(req: &FlowyRequest, payload: &mut Payload) -> Self::Future {
                $tuple_type {
                    items: <($(Option<$T>,)+)>::default(),
                    futs: FromRequestFutures($($T::from_request(req, payload),)+),
                }
            }
        }

        #[doc(hidden)]
        #[pin_project::pin_project]
        pub struct $tuple_type<$($T: FromRequest),+> {
            items: ($(Option<$T>,)+),
            #[pin]
            futs: FromRequestFutures<$($T,)+>,
        }

        impl<$($T: FromRequest),+> Future for $tuple_type<$($T),+>
        {
            type Output = Result<($($T,)+), Error>;

            fn poll(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
                let mut this = self.project();
                let mut ready = true;
                $(
                    if this.items.$n.is_none() {
                        match this.futs.as_mut().project().$n.poll(cx) {
                            Poll::Ready(Ok(item)) => this.items.$n = Some(item),
                            Poll::Pending => ready = false,
                            Poll::Ready(Err(e)) => return Poll::Ready(Err(e.into())),
                        }
                    }
                )+

                if ready {
                    Poll::Ready(Ok(
                        ($(this.items.$n.take().unwrap(),)+)
                    ))
                } else {
                    Poll::Pending
                }
            }
        }
    }
});

factory_tuple! {}
factory_tuple! { A }
factory_tuple! { A B }
factory_tuple! { A B C }
factory_tuple! { A B C D }
factory_tuple! { A B C D E }

#[rustfmt::skip]
mod m {
    use super::*;
    tuple_from_req!(TupleFromRequest1, (0, A));
    tuple_from_req!(TupleFromRequest2, (0, A), (1, B));
    tuple_from_req!(TupleFromRequest3, (0, A), (1, B), (2, C));
    tuple_from_req!(TupleFromRequest4, (0, A), (1, B), (2, C), (3, D));
    tuple_from_req!(TupleFromRequest5, (0, A), (1, B), (2, C), (3, D), (4, E));
}
