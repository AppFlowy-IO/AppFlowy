use crate::errors::{ErrorCode, Kind, ServerError};
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use std::{convert::TryInto, error::Error, fmt::Debug};
use tokio::sync::oneshot::error::RecvError;

#[derive(Debug, Serialize, Deserialize)]
pub struct FlowyResponse {
    pub data: Bytes,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<ServerError>,
}

impl FlowyResponse {
    pub fn new(data: Bytes, error: Option<ServerError>) -> Self { FlowyResponse { data, error } }

    pub fn success() -> Self { Self::new(Bytes::new(), None) }

    pub fn data<T: TryInto<Bytes, Error = protobuf::ProtobufError>>(
        mut self,
        data: T,
    ) -> Result<Self, ServerError> {
        let bytes: Bytes = data.try_into()?;
        self.data = bytes;
        Ok(self)
    }
}

impl std::convert::From<protobuf::ProtobufError> for ServerError {
    fn from(e: protobuf::ProtobufError) -> Self { ServerError::internal().context(e) }
}

impl std::convert::From<RecvError> for ServerError {
    fn from(error: RecvError) -> Self { ServerError::internal().context(error) }
}

impl std::convert::From<serde_json::Error> for ServerError {
    fn from(e: serde_json::Error) -> Self { ServerError::internal().context(e) }
}

impl std::convert::From<anyhow::Error> for ServerError {
    fn from(error: anyhow::Error) -> Self { ServerError::internal().context(error) }
}

impl std::convert::From<reqwest::Error> for ServerError {
    fn from(error: reqwest::Error) -> Self {
        if error.is_timeout() {
            return ServerError::connect_timeout().context(error);
        }

        if error.is_request() {
            let hyper_error: Option<&hyper::Error> = error.source().unwrap().downcast_ref();
            return match hyper_error {
                None => ServerError::connect_refused().context(error),
                Some(hyper_error) => {
                    let mut code = ErrorCode::InternalError;
                    let msg = format!("{}", error);
                    if hyper_error.is_closed() {
                        code = ErrorCode::ConnectClose;
                    }

                    if hyper_error.is_connect() {
                        code = ErrorCode::ConnectRefused;
                    }

                    if hyper_error.is_canceled() {
                        code = ErrorCode::ConnectCancel;
                    }

                    if hyper_error.is_timeout() {}

                    ServerError {
                        code,
                        msg,
                        kind: Kind::Other,
                    }
                },
            };
        }

        ServerError::internal().context(error)
    }
}

impl std::convert::From<uuid::Error> for ServerError {
    fn from(e: uuid::Error) -> Self { ServerError::internal().context(e) }
}
