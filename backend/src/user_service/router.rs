use crate::routers::utils::parse_from_payload;
use actix_web::{
    web::{Data, Payload},
    HttpRequest,
    HttpResponse,
};

use crate::user_service::{get_user_details, register_user, sign_in, sign_out};
use actix_identity::Identity;
use flowy_net::{errors::ServerError, response::FlowyResponse};
use flowy_user::protobuf::{QueryUserDetailParams, SignInParams, SignOutParams, SignUpParams};
use sqlx::PgPool;

pub async fn sign_in_handler(
    payload: Payload,
    id: Identity,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: SignInParams = parse_from_payload(payload).await?;
    let data = sign_in(pool.get_ref(), params).await?;
    id.remember(data.token.clone());
    let response = FlowyResponse::success().pb(data)?;
    Ok(response.into())
}

pub async fn sign_out_handler(payload: Payload, id: Identity) -> Result<HttpResponse, ServerError> {
    let params: SignOutParams = parse_from_payload(payload).await?;
    id.forget();

    let response = sign_out(params).await?;
    Ok(response.into())
}

pub async fn user_detail_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: QueryUserDetailParams = parse_from_payload(payload).await?;
    let response = get_user_details(pool.get_ref(), &params.token).await?;
    Ok(response.into())
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
