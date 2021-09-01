use crate::routers::utils::parse_from_payload;
use actix_web::{
    web::{Data, Payload},
    HttpRequest,
    HttpResponse,
};

use crate::user_service::{
    get_user_details,
    register_user,
    set_user_detail,
    sign_in,
    sign_out,
    LoggedUser,
};
use actix_identity::Identity;
use flowy_net::{errors::ServerError, response::FlowyResponse};
use flowy_user::protobuf::{SignInParams, SignUpParams, UpdateUserParams, UserToken};
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
    let params: UserToken = parse_from_payload(payload).await?;
    id.forget();

    let response = sign_out(params).await?;
    Ok(response.into())
}

pub async fn get_user_detail_handler(
    logged_user: LoggedUser,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let response = get_user_details(pool.get_ref(), logged_user).await?;
    Ok(response.into())
}

pub async fn set_user_detail_handler(
    logged_user: LoggedUser,
    pool: Data<PgPool>,
    payload: Payload,
) -> Result<HttpResponse, ServerError> {
    let params: UpdateUserParams = parse_from_payload(payload).await?;
    let response = set_user_detail(pool.get_ref(), logged_user, params).await?;
    Ok(response.into())
}

pub async fn register_handler(
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
