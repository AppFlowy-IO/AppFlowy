use crate::{
    entities::{logged_user::LoggedUser, token::Token},
    services::user::{get_user_profile, register_user, set_user_profile, sign_in, sign_out},
    util::serde_ext::parse_from_payload,
};
use actix_identity::Identity;
use actix_web::{
    web::{Data, Payload},
    HttpRequest,
    HttpResponse,
};
use backend_service::{errors::ServerError, response::FlowyResponse};
use flowy_user_data_model::protobuf::{
    SignInParams as SignInParamsPB,
    SignUpParams as SignUpParamsPB,
    UpdateUserParams as UpdateUserParamsPB,
};
use sqlx::PgPool;

pub async fn sign_in_handler(payload: Payload, id: Identity, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: SignInParamsPB = parse_from_payload(payload).await?;
    let data = sign_in(pool.get_ref(), params).await?;
    id.remember(data.token.clone());
    let response = FlowyResponse::success().pb(data)?;
    Ok(response.into())
}

pub async fn sign_out_handler(logged_user: LoggedUser, id: Identity) -> Result<HttpResponse, ServerError> {
    id.forget();

    let response = sign_out(logged_user).await?;
    Ok(response.into())
}

pub async fn get_user_profile_handler(
    token: Token,
    logged_user: LoggedUser,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let response = get_user_profile(pool.get_ref(), token, logged_user).await?;
    Ok(response.into())
}

pub async fn set_user_profile_handler(
    logged_user: LoggedUser,
    pool: Data<PgPool>,
    payload: Payload,
) -> Result<HttpResponse, ServerError> {
    let params: UpdateUserParamsPB = parse_from_payload(payload).await?;
    let response = set_user_profile(pool.get_ref(), logged_user, params).await?;
    Ok(response.into())
}

pub async fn register_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: SignUpParamsPB = parse_from_payload(payload).await?;
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
