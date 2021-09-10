use crate::routers::utils::parse_from_payload;
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use flowy_document::protobuf::CreateDocParams;
use flowy_net::errors::ServerError;
use sqlx::PgPool;

pub async fn create_handler(
    payload: Payload,
    _pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let _params: CreateDocParams = parse_from_payload(payload).await?;
    unimplemented!()
}

pub async fn read_handler(
    _payload: Payload,
    _pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}

pub async fn update_handler(
    _payload: Payload,
    _pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}

pub async fn delete_handler(
    _payload: Payload,
    _pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}
