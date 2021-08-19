use crate::user_service::Auth;
use actix_web::{
    web::{Data, Payload},
    Error,
    HttpRequest,
    HttpResponse,
};
use flowy_user::protobuf::SignUpRequest;

use crate::{entities::ServerResponse, routers::helper::parse_from_payload};

use std::sync::Arc;

pub async fn user_register(
    request: HttpRequest,
    payload: Payload,
    auth: Data<Arc<Auth>>,
) -> Result<HttpResponse, Error> {
    let request: SignUpRequest = parse_from_payload(payload).await?;
    // ProtobufError
    let resp = ServerResponse::success();
    Ok(resp.into())
}
