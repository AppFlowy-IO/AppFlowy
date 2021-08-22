use crate::routers::helper::parse_from_payload;
use actix_web::{
    web::{Data, Payload},
    Error,
    HttpRequest,
    HttpResponse,
};
use flowy_net::response::*;
use flowy_user::protobuf::SignUpParams;

use crate::user_service::sign_up;
use sqlx::PgPool;
use std::sync::Arc;

pub async fn register(
    _request: HttpRequest,
    payload: Payload,
    pool: Data<PgPool>,
) -> Result<HttpResponse, ServerError> {
    let params: SignUpParams = parse_from_payload(payload).await?;
    let resp = sign_up(pool.get_ref(), params).await?;

    Ok(resp.into())
}
