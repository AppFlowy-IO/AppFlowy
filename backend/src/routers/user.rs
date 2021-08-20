use crate::{routers::helper::parse_from_payload, user_service::Auth};
use actix_web::{
    web::{Data, Payload},
    Error,
    HttpRequest,
    HttpResponse,
};
use flowy_net::response::*;
use flowy_user::protobuf::SignUpParams;

use std::sync::Arc;

pub async fn register(
    _request: HttpRequest,
    payload: Payload,
    auth: Data<Arc<Auth>>,
) -> Result<HttpResponse, Error> {
    let params: SignUpParams = parse_from_payload(payload).await?;
    let _ = auth.sign_up(params)?;

    let resp = FlowyResponse::success();

    Ok(resp.into())
}
