use crate::entities::{ServerCode, ServerResponse};
use actix_web::{error::ResponseError, HttpResponse};
use protobuf::ProtobufError;
use std::fmt::Formatter;

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

impl ResponseError for ServerError {
    fn error_response(&self) -> HttpResponse {
        match self {
            ServerError::InternalError(msg) => {
                let msg = format!("Internal Server Error. {}", msg);
                let resp = ServerResponse::from_msg(&msg, ServerCode::InternalError);
                HttpResponse::InternalServerError().json(resp)
            },
            ServerError::BadRequest(ref resp) => HttpResponse::BadRequest().json(resp),
            ServerError::Unauthorized => {
                let resp = ServerResponse::from_msg("Unauthorized", ServerCode::Unauthorized);
                HttpResponse::Unauthorized().json(resp)
            },
        }
    }
}

impl std::convert::From<ProtobufError> for ServerError {
    fn from(err: ProtobufError) -> Self {
        let msg = format!("{:?}", err);
        ServerError::InternalError(msg)
    }
}
