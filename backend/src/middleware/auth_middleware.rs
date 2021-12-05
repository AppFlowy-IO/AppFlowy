use crate::service::user::{LoggedUser, AUTHORIZED_USERS};
use actix_service::{Service, Transform};
use actix_web::{
    dev::{ServiceRequest, ServiceResponse},
    Error,
    HttpResponse,
    ResponseError,
};

use crate::config::IGNORE_ROUTES;
use actix_web::{body::AnyBody, dev::MessageBody};
use backend_service::{configuration::HEADER_TOKEN, errors::ServerError};
use futures::future::{ok, LocalBoxFuture, Ready};
use std::{
    convert::TryInto,
    error::Error as StdError,
    task::{Context, Poll},
};

pub struct AuthenticationService;

impl<S, B> Transform<S, ServiceRequest> for AuthenticationService
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: MessageBody + 'static,
    B::Error: StdError,
{
    type Response = ServiceResponse;
    type Error = Error;
    type Transform = AuthenticationMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future { ok(AuthenticationMiddleware { service }) }
}
pub struct AuthenticationMiddleware<S> {
    service: S,
}

impl<S, B> Service<ServiceRequest> for AuthenticationMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: MessageBody + 'static,
    B::Error: StdError,
{
    type Response = ServiceResponse;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn poll_ready(&self, cx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> { self.service.poll_ready(cx) }

    fn call(&self, req: ServiceRequest) -> Self::Future {
        let mut authenticate_pass: bool = false;
        for ignore_route in IGNORE_ROUTES.iter() {
            // tracing::info!("ignore: {}, path: {}", ignore_route, req.path());
            if req.path().starts_with(ignore_route) {
                authenticate_pass = true;
                break;
            }
        }

        if !authenticate_pass {
            if let Some(header) = req.headers().get(HEADER_TOKEN) {
                let result: Result<LoggedUser, ServerError> = header.try_into();
                match result {
                    Ok(logged_user) => {
                        if cfg!(feature = "ignore_auth") {
                            authenticate_pass = true;
                            AUTHORIZED_USERS.store_auth(logged_user, true);
                        } else {
                            authenticate_pass = AUTHORIZED_USERS.is_authorized(&logged_user);
                            if authenticate_pass {
                                AUTHORIZED_USERS.store_auth(logged_user, true);
                            }
                        }
                    },
                    Err(e) => log::error!("{:?}", e),
                }
            } else {
                tracing::debug!("Can't find any token from request: {:?}", req);
            }
        }

        if authenticate_pass {
            let fut = self.service.call(req);
            Box::pin(async move {
                let res = fut.await?;
                Ok(res.map_body(|_, body| AnyBody::from_message(body)))
            })
        } else {
            Box::pin(async move { Ok(req.into_response(unauthorized_response())) })
        }
    }
}

fn unauthorized_response() -> HttpResponse {
    let error = ServerError::unauthorized();
    error.error_response()
}
