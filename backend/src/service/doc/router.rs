use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use sqlx::PgPool;

use flowy_document::protobuf::{QueryDocParams, UpdateDocParams};
use flowy_net::errors::ServerError;

use crate::service::{
    doc::{read_doc, update_doc},
    util::parse_from_payload,
};
use flowy_net::response::FlowyResponse;

pub async fn read_handler(
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: QueryDocParams = parse_from_payload(payload).await?;
    let doc = read_doc(pool.get_ref(), params).await?;
    let response = FlowyResponse::success().pb(doc)?;
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
