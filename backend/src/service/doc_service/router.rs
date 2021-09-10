use crate::{
    routers::utils::parse_from_payload,
    service::doc_service::{create_doc, read_doc, update_doc},
};
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use flowy_document::protobuf::{CreateDocParams, QueryDocParams, UpdateDocParams};
use flowy_net::errors::ServerError;
use sqlx::PgPool;

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: CreateDocParams = parse_from_payload(payload).await?;
    let response = create_doc(pool.get_ref(), params).await?;
    Ok(response.into())
}

pub async fn read_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: QueryDocParams = parse_from_payload(payload).await?;
    let response = read_doc(pool.get_ref(), params).await?;
    Ok(response.into())
}

pub async fn update_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: UpdateDocParams = parse_from_payload(payload).await?;
    let response = update_doc(pool.get_ref(), params).await?;
    Ok(response.into())
}

pub async fn delete_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: QueryDocParams = parse_from_payload(payload).await?;
    let response = read_doc(pool.get_ref(), params).await?;
    Ok(response.into())
}
