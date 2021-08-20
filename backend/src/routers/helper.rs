use crate::config::MAX_PAYLOAD_SIZE;
use actix_web::web;
use flowy_net::{errors::NetworkError, response::*};
use futures::StreamExt;
use protobuf::{Message, ProtobufResult};

pub async fn parse_from_payload<T: Message>(payload: web::Payload) -> Result<T, NetworkError> {
    let bytes = poll_payload(payload).await?;
    parse_from_bytes(&bytes)
}

pub fn parse_from_bytes<T: Message>(bytes: &[u8]) -> Result<T, NetworkError> {
    let result: ProtobufResult<T> = Message::parse_from_bytes(&bytes);
    match result {
        Ok(data) => Ok(data),
        Err(e) => Err(e.into()),
    }
}

pub async fn poll_payload(mut payload: web::Payload) -> Result<web::BytesMut, NetworkError> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk.map_err(|e| NetworkError::InternalError(format!("{:?}", e)))?;
        if (body.len() + chunk.len()) > MAX_PAYLOAD_SIZE {
            let resp = FlowyResponse::from_msg("Payload overflow", ServerCode::PayloadOverflow);
            return Err(NetworkError::BadRequest(resp));
        }
        body.extend_from_slice(&chunk);
    }
    Ok(body)
}
