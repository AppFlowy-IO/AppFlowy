use crate::service::{
    doc::{create_doc, read_doc, update_doc},
    util::parse_from_payload,
};
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use anyhow::Context;
use flowy_document_infra::protobuf::{CreateDocParams, DocIdentifier, UpdateDocParams};
use flowy_net::{errors::ServerError, response::FlowyResponse};
use sqlx::PgPool;

pub async fn create_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: CreateDocParams = parse_from_payload(payload).await?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create doc")?;

    let _ = create_doc(&mut transaction, params).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create doc.")?;

    Ok(FlowyResponse::success().into())
}

#[tracing::instrument(level = "debug", skip(payload, pool), err)]
pub async fn read_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: DocIdentifier = parse_from_payload(payload).await?;
    let doc = read_doc(pool.get_ref(), params).await?;
    let response = FlowyResponse::success().pb(doc)?;
    Ok(response.into())
}

pub async fn update_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: UpdateDocParams = parse_from_payload(payload).await?;
    let _ = update_doc(pool.get_ref(), params).await?;
    Ok(FlowyResponse::success().into())
}
