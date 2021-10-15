use crate::service::{
    trash::{create_trash, delete_trash, read_trash},
    user::LoggedUser,
    util::parse_from_payload,
};
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use flowy_net::errors::ServerError;
use flowy_workspace::protobuf::{CreateTrashParams, TrashIdentifiers};
use sqlx::PgPool;

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: CreateTrashParams = parse_from_payload(payload).await?;
    let resp = create_trash(pool.get_ref(), params, logged_user).await?;
    Ok(resp.into())
}

pub async fn delete_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: TrashIdentifiers = parse_from_payload(payload).await?;
    let resp = delete_trash(pool.get_ref(), params).await?;
    Ok(resp.into())
}

pub async fn read_handler(pool: Data<PgPool>, logged_user: LoggedUser) -> Result<HttpResponse, ServerError> {
    let resp = read_trash(pool.get_ref(), logged_user).await?;
    Ok(resp.into())
}
