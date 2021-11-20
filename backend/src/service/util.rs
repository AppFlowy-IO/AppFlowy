use crate::config::MAX_PAYLOAD_SIZE;
use actix_web::web;
use backend_service::errors::{ErrorCode, ServerError};
use futures::StreamExt;
use protobuf::{Message, ProtobufResult};

pub async fn parse_from_payload<T: Message>(payload: web::Payload) -> Result<T, ServerError> {
    let bytes = poll_payload(&mut payload.into_inner()).await?;
    parse_from_bytes(&bytes)
}

#[allow(dead_code)]
pub async fn parse_from_dev_payload<T: Message>(payload: &mut actix_web::dev::Payload) -> Result<T, ServerError> {
    let bytes = poll_payload(payload).await?;
    parse_from_bytes(&bytes)
}

#[inline]
pub fn md5<T: AsRef<[u8]>>(data: T) -> String {
    let md5 = format!("{:x}", md5::compute(data));
    md5
}

pub fn parse_from_bytes<T: Message>(bytes: &[u8]) -> Result<T, ServerError> {
    let result: ProtobufResult<T> = Message::parse_from_bytes(&bytes);
    match result {
        Ok(data) => Ok(data),
        Err(e) => Err(e.into()),
    }
}

pub async fn poll_payload(payload: &mut actix_web::dev::Payload) -> Result<web::BytesMut, ServerError> {
    let mut body = web::BytesMut::new();
    while let Some(chunk) = payload.next().await {
        let chunk = chunk.map_err(|err| ServerError::internal().context(err))?;

        if (body.len() + chunk.len()) > MAX_PAYLOAD_SIZE {
            return Err(ServerError::new(
                "Payload overflow".to_string(),
                ErrorCode::PayloadOverflow,
            ));
        }
        body.extend_from_slice(&chunk);
    }
    Ok(body)
}
