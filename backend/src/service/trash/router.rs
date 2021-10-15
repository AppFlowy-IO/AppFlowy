use crate::service::util::parse_from_payload;
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use flowy_net::errors::ServerError;
use flowy_workspace::protobuf::{Trash, TrashIdentifiers};
use sqlx::PgPool;

pub async fn create_handler(payload: Payload, _pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let _params: Trash = parse_from_payload(payload).await?;
    unimplemented!()
}

pub async fn delete_handler(payload: Payload, _pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let _params: TrashIdentifiers = parse_from_payload(payload).await?;
    unimplemented!()
}

pub async fn read_handler(payload: Payload, _pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let _params: TrashIdentifiers = parse_from_payload(payload).await?;
    unimplemented!()
}
