use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use sqlx::PgPool;

use flowy_net::errors::ServerError;
use flowy_workspace::protobuf::{
    CreateAppParams,
    DeleteAppParams,
    QueryAppParams,
    UpdateAppParams,
};

use crate::{
    routers::utils::parse_from_payload,
    service::{
        user_service::LoggedUser,
        workspace_service::app::app::{create_app, delete_app, read_app, update_app},
    },
};

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: CreateAppParams = parse_from_payload(payload).await?;
    let resp = create_app(pool.get_ref(), params, logged_user).await?;
    Ok(resp.into())
}

pub async fn read_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: QueryAppParams = parse_from_payload(payload).await?;
    let resp = read_app(pool.get_ref(), params).await?;
    Ok(resp.into())
}

pub async fn update_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: UpdateAppParams = parse_from_payload(payload).await?;
    let resp = update_app(pool.get_ref(), params).await?;
    Ok(resp.into())
}

pub async fn delete_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: DeleteAppParams = parse_from_payload(payload).await?;
    let resp = delete_app(pool.get_ref(), &params.app_id).await?;
    Ok(resp.into())
}
