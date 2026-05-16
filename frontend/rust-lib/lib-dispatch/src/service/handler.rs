use std::{
  future::Future,
  marker::PhantomData,
  pin::Pin,
  task::{Context, Poll},
};

use futures_core::ready;
use pin_project::pin_project;

use crate::dispatcher::AFConcurrent;
use crate::{
  errors::DispatchError,
  request::{AFPluginEventRequest, FromAFPluginRequest},
  response::{AFPluginEventResponse, AFPluginResponder},
  service::{AFPluginServiceFactory, Service, ServiceRequest, ServiceResponse},
  util::ready::*,
};

/// A closure that is run every time for the specified plugin event
pub trait AFPluginHandler<T, R>: Clone + AFConcurrent + 'static
where
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  fn call(&self, param: T) -> R;
}

pub struct AFPluginHandlerService<H, T, R>
where
  H: AFPluginHandler<T, R>,
  T: FromAFPluginRequest,
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  handler: H,
  _phantom: PhantomData<(T, R)>,
}

impl<H, T, R> AFPluginHandlerService<H, T, R>
where
  H: AFPluginHandler<T, R>,
  T: FromAFPluginRequest,
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  pub fn new(handler: H) -> Self {
    Self {
      handler,
      _phantom: PhantomData,
    }
  }
}

impl<H, T, R> Clone for AFPluginHandlerService<H, T, R>
where
  H: AFPluginHandler<T, R>,
  T: FromAFPluginRequest,
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  fn clone(&self) -> Self {
    Self {
      handler: self.handler.clone(),
      _phantom: PhantomData,
    }
  }
}

impl<F, T, R> AFPluginServiceFactory<ServiceRequest> for AFPluginHandlerService<F, T, R>
where
  F: AFPluginHandler<T, R>,
  T: FromAFPluginRequest,
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  type Response = ServiceResponse;
  type Error = DispatchError;
  type Service = Self;
  type Context = ();
  type Future = Ready<Result<Self::Service, Self::Error>>;

  fn new_service(&self, _: ()) -> Self::Future {
    ready(Ok(self.clone()))
  }
}

impl<H, T, R> Service<ServiceRequest> for AFPluginHandlerService<H, T, R>
where
  H: AFPluginHandler<T, R>,
  T: FromAFPluginRequest,
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  type Response = ServiceResponse;
  type Error = DispatchError;
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
  H: AFPluginHandler<T, R>,
  T: FromAFPluginRequest,
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  Extract(#[pin] T::Future, Option<AFPluginEventRequest>, H),
  Handle(#[pin] R, Option<AFPluginEventRequest>),
}

impl<F, T, R> Future for HandlerServiceFuture<F, T, R>
where
  F: AFPluginHandler<T, R>,
  T: FromAFPluginRequest,
  R: Future + AFConcurrent,
  R::Output: AFPluginResponder,
{
  type Output = Result<ServiceResponse, DispatchError>;

  fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
    loop {
      match self.as_mut().project() {
        HandlerServiceProj::Extract(fut, req, handle) => {
          match ready!(fut.poll(cx)) {
            Ok(params) => {
              let fut = handle.call(params);
              let state = HandlerServiceFuture::Handle(fut, req.take());
              self.as_mut().set(state);
            },
            Err(err) => {
              let req = req.take().unwrap();
              let system_err: DispatchError = err.into();
              let res: AFPluginEventResponse = system_err.into();
              return Poll::Ready(Ok(ServiceResponse::new(req, res)));
            },
          };
        },
        HandlerServiceProj::Handle(fut, req) => {
          let result = ready!(fut.poll(cx));
          let req = req.take().unwrap();
          let resp = result.respond_to(&req);
          return Poll::Ready(Ok(ServiceResponse::new(req, resp)));
        },
      }
    }
  }
}

macro_rules! factory_tuple ({ $($param:ident)* } => {
    impl<Func, $($param,)* Res> AFPluginHandler<($($param,)*), Res> for Func
    where Func: Fn($($param),*) -> Res + Clone + 'static + AFConcurrent,
          Res: Future + AFConcurrent,
          Res::Output: AFPluginResponder,
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
        struct FromRequestFutures<$($T: FromAFPluginRequest),+>($(#[pin] $T::Future),+);

        /// FromRequest implementation for tuple
        #[doc(hidden)]
        #[allow(unused_parens)]
        impl<$($T: FromAFPluginRequest + 'static),+> FromAFPluginRequest for ($($T,)+)
        {
            type Error = DispatchError;
            type Future = $tuple_type<$($T),+>;

            fn from_request(req: &AFPluginEventRequest, payload: &mut crate::prelude::Payload) -> Self::Future {
                $tuple_type {
                    items: <($(Option<$T>,)+)>::default(),
                    futs: FromRequestFutures($($T::from_request(req, payload),)+),
                }
            }
        }

        #[doc(hidden)]
        #[pin_project::pin_project]
        pub struct $tuple_type<$($T: FromAFPluginRequest),+> {
            items: ($(Option<$T>,)+),
            #[pin]
            futs: FromRequestFutures<$($T,)+>,
        }

        impl<$($T: FromAFPluginRequest),+> Future for $tuple_type<$($T),+>
        {
            type Output = Result<($($T,)+), DispatchError>;

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
