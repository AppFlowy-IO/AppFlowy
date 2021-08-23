use crate::routers::utils::parse_from_payload;
use actix_web::{
    web::{Data, Payload},
    Error,
    HttpRequest,
    HttpResponse,
};
use flowy_net::response::*;
use flowy_user::protobuf::{SignInParams, SignUpParams};

use crate::user_service::auth_service::{register_user, sign_in};
use actix_identity::Identity;
use flowy_net::errors::ServerError;
use sqlx::PgPool;
use std::sync::Arc;

pub async fn sign_in_handler(
    payload: Payload,
    id: Identity,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: SignInParams = parse_from_payload(payload).await?;
    let resp = sign_in(pool.get_ref(), params, id).await?;
    Ok(resp.into())
}

pub async fn sign_out_handler(id: Identity) -> Result<HttpResponse, ServerError> {
    id.forget();
    Ok(HttpResponse::Ok().finish())
}

pub async fn user_profile(
    request: HttpRequest,
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}

pub async fn register_user_handler(
    _request: HttpRequest,
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: SignUpParams = parse_from_payload(payload).await?;
    let resp = register_user(pool.get_ref(), params).await?;

    Ok(resp.into())
}

pub async fn change_password(
    request: HttpRequest,
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}
