use crate::response::ServerResponse;
use protobuf::ProtobufError;
use std::fmt::{Formatter, Write};

#[derive(Debug)]
pub enum ServerError {
    InternalError(String),
    BadRequest(ServerResponse<String>),
    Unauthorized,
}

impl std::fmt::Display for ServerError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            ServerError::InternalError(_) => f.write_str("Internal Server Error"),
            ServerError::BadRequest(request) => {
                let msg = format!("Bad Request: {:?}", request);
                f.write_str(&msg)
            },
            ServerError::Unauthorized => f.write_str("Unauthorized"),
        }
    }
}

impl std::convert::From<ProtobufError> for ServerError {
    fn from(err: ProtobufError) -> Self {
        let msg = format!("{:?}", err);
        ServerError::InternalError(msg)
    }
}
