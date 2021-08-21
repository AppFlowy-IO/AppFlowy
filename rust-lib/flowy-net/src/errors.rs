use crate::response::FlowyResponse;
use protobuf::ProtobufError;
use std::fmt::{Formatter, Write};

#[derive(Debug)]
pub enum NetworkError {
    InternalError(String),
    ProtobufError(ProtobufError),
    BadRequest(FlowyResponse<String>),
    Unauthorized,
}

impl std::fmt::Display for NetworkError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            NetworkError::InternalError(_) => f.write_str("Internal Server Error"),
            NetworkError::ProtobufError(err) => f.write_str(&format!("protobuf error: {}", err)),
            NetworkError::BadRequest(request) => {
                let msg = format!("Bad Request: {:?}", request);
                f.write_str(&msg)
            },
            NetworkError::Unauthorized => f.write_str("Unauthorized"),
        }
    }
}

impl std::convert::From<ProtobufError> for NetworkError {
    fn from(err: ProtobufError) -> Self { NetworkError::ProtobufError(err) }
}

impl std::convert::From<reqwest::Error> for NetworkError {
    fn from(error: reqwest::Error) -> Self {
        let msg = format!("{:?}", error);
        NetworkError::InternalError(msg)
    }
}

impl std::convert::From<String> for NetworkError {
    fn from(error: String) -> Self { NetworkError::InternalError(error) }
}
