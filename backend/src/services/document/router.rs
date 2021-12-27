use crate::{
    context::FlowyPersistence,
    services::document::persistence::{create_document, read_document, reset_document},
    util::serde_ext::parse_from_payload,
};
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use backend_service::{errors::ServerError, response::FlowyResponse};
use flowy_collaboration::protobuf::{CreateDocParams, DocIdentifier, ResetDocumentParams};
use sqlx::PgPool;
use std::sync::Arc;

pub async fn create_document_handler(
    payload: Payload,
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
    let params: CreateDocParams = parse_from_payload(payload).await?;
    let kv_store = persistence.kv_store();
    let _ = create_document(&kv_store, params).await?;
    Ok(FlowyResponse::success().into())
}

#[tracing::instrument(level = "debug", skip(payload, persistence), err)]
pub async fn read_document_handler(
    payload: Payload,
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
    let params: DocIdentifier = parse_from_payload(payload).await?;
    let doc = read_document(persistence.get_ref(), params).await?;
    let response = FlowyResponse::success().pb(doc)?;
    Ok(response.into())
}

pub async fn reset_document_handler(
    payload: Payload,
    persistence: Data<Arc<FlowyPersistence>>,
) -> Result<HttpResponse, ServerError> {
    let params: ResetDocumentParams = parse_from_payload(payload).await?;
    let kv_store = persistence.kv_store();
    let _ = reset_document(&kv_store, params).await?;
    Ok(FlowyResponse::success().into())
}
