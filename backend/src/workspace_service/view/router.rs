use actix_identity::Identity;
use actix_web::{
    web::{Data, Payload},
    Error,
    HttpRequest,
    HttpResponse,
};
use flowy_net::errors::ServerError;
use sqlx::PgPool;

pub async fn create_view(
    payload: Payload,
    id: Identity,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}

pub async fn read_view(
    payload: Payload,
    id: Identity,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}

pub async fn update_view(
    payload: Payload,
    id: Identity,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}

pub async fn delete_view(
    payload: Payload,
    id: Identity,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    unimplemented!()
}
