use crate::{
    config::MAX_PAYLOAD_SIZE,
    entities::{ServerCode, ServerResponse},
    errors::ServerError,
};
use actix_web::web;
use futures::StreamExt;
use protobuf::{Message, ProtobufResult};

pub async fn parse_from_payload<T: Message>(payload: web::Payload) -> Result<T, ServerError> {
    let bytes = poll_payload(payload).await?;
    parse_from_bytes(&bytes)
}

pub fn parse_from_bytes<T: Message>(bytes: &[u8]) -> Result<T, ServerError> {
    let result: ProtobufResult<T> = Message::parse_from_bytes(&bytes);
    match result {
        Ok(data) => Ok(data),
        Err(e) => Err(e.into()),
    }
}

pub async fn poll_payload(mut payload: web::Payload) -> Result<web::BytesMut, ServerError> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk.map_err(|e| ServerError::InternalError(format!("{:?}", e)))?;
        if (body.len() + chunk.len()) > MAX_PAYLOAD_SIZE {
            let resp = ServerResponse::from_msg("Payload overflow", ServerCode::PayloadOverflow);
            return Err(ServerError::BadRequest(resp));
        }
        body.extend_from_slice(&chunk);
    }
    Ok(body)
}
