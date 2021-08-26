use crate::routers::utils::parse_from_payload;
use actix_web::{
    web::{Data, Payload},
    HttpRequest,
    HttpResponse,
};

use flowy_user::protobuf::{SignInParams, SignUpParams};

use crate::user_service::{register_user, sign_in};
use actix_identity::Identity;
use flowy_net::errors::ServerError;
use sqlx::PgPool;

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
    _request: HttpRequest,
    _payload: Payload,
    _pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}

pub async fn register_user_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: SignUpParams = parse_from_payload(payload).await?;
    let resp = register_user(pool.get_ref(), params).await?;

    Ok(resp.into())
}

pub async fn change_password(
    _request: HttpRequest,
    _payload: Payload,
    _pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}
