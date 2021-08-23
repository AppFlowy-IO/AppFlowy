use crate::errors::{Code, ServerError};
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

    pub fn success<T: TryInto<Bytes, Error = protobuf::ProtobufError>>(
        data: T,
    ) -> Result<Self, ServerError> {
        let bytes: Bytes = data.try_into()?;
        Ok(Self::new(bytes, None))
    }
}

impl std::convert::From<protobuf::ProtobufError> for ServerError {
    fn from(err: protobuf::ProtobufError) -> Self {
        ServerError {
            code: Code::ProtobufError,
            msg: format!("{}", err),
        }
    }
}

impl std::convert::From<RecvError> for ServerError {
    fn from(error: RecvError) -> Self { ServerError::internal().with_msg(error) }
}

impl std::convert::From<serde_json::Error> for ServerError {
    fn from(e: serde_json::Error) -> Self {
        let msg = format!("Serial error: {:?}", e);
        ServerError {
            code: Code::SerdeError,
            msg,
        }
    }
}

impl std::convert::From<anyhow::Error> for ServerError {
    fn from(error: anyhow::Error) -> Self { ServerError::internal().with_msg(error) }
}

impl std::convert::From<reqwest::Error> for ServerError {
    fn from(error: reqwest::Error) -> Self {
        if error.is_timeout() {
            return ServerError {
                code: Code::ConnectTimeout,
                msg: format!("{}", error),
            };
        }

        if error.is_request() {
            let hyper_error: Option<&hyper::Error> = error.source().unwrap().downcast_ref();
            return match hyper_error {
                None => ServerError {
                    code: Code::ConnectRefused,
                    msg: format!("{:?}", error),
                },
                Some(hyper_error) => {
                    let mut code = Code::InternalError;
                    let msg = format!("{}", error);
                    if hyper_error.is_closed() {
                        code = Code::ConnectClose;
                    }

                    if hyper_error.is_connect() {
                        code = Code::ConnectRefused;
                    }

                    if hyper_error.is_canceled() {
                        code = Code::ConnectCancel;
                    }

                    if hyper_error.is_timeout() {}

                    ServerError { code, msg }
                },
            };
        }

        let msg = format!("{:?}", error);
        ServerError {
            code: Code::ProtobufError,
            msg,
        }
    }
}
