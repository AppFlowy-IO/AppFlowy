use crate::{
    context::FlowyPersistence,
    services::document::persistence::{create_doc, read_doc, update_doc},
    util::serde_ext::parse_from_payload,
};
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use backend_service::{errors::ServerError, response::FlowyResponse};
use flowy_collaboration::protobuf::{CreateDocParams, DocIdentifier, UpdateDocParams};
use sqlx::PgPool;
use std::sync::Arc;

pub async fn create_handler(
    payload: Payload,
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
    let params: CreateDocParams = parse_from_payload(payload).await?;
    let _ = create_doc(persistence.get_ref(), params).await?;
    Ok(FlowyResponse::success().into())
}

#[tracing::instrument(level = "debug", skip(payload, persistence), err)]
pub async fn read_handler(
    payload: Payload,
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
    let params: DocIdentifier = parse_from_payload(payload).await?;
    let doc = read_doc(persistence.get_ref(), params).await?;
    let response = FlowyResponse::success().pb(doc)?;
    Ok(response.into())
}

pub async fn update_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: UpdateDocParams = parse_from_payload(payload).await?;
    let _ = update_doc(pool.get_ref(), params).await?;
    Ok(FlowyResponse::success().into())
}
