use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use sqlx::PgPool;

use flowy_net::errors::ServerError;
use flowy_workspace::protobuf::{CreateViewParams, DeleteViewParams, QueryViewParams, UpdateViewParams};

use crate::service::{
    doc::doc::DocBiz,
    util::parse_from_payload,
    view::{create_view, delete_view, read_view, update_view},
};
use std::sync::Arc;

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    _doc_biz: Data<Arc<DocBiz>>,
) -> Result<HttpResponse, ServerError> {
    let params: CreateViewParams = parse_from_payload(payload).await?;
    let resp = create_view(pool.get_ref(), params).await?;
    Ok(resp.into())
}

pub async fn read_handler(
    payload: Payload,
    pool: Data<PgPool>,
    doc_biz: Data<Arc<DocBiz>>,
) -> Result<HttpResponse, ServerError> {
    let params: QueryViewParams = parse_from_payload(payload).await?;
    let resp = read_view(pool.get_ref(), params, doc_biz).await?;
    Ok(resp.into())
}

pub async fn update_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: UpdateViewParams = parse_from_payload(payload).await?;
    let resp = update_view(pool.get_ref(), params).await?;
    Ok(resp.into())
}

pub async fn delete_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: DeleteViewParams = parse_from_payload(payload).await?;
    let resp = delete_view(pool.get_ref(), &params.view_id).await?;
    Ok(resp.into())
}
