use crate::{entities::ServerCode, errors::ServerError};
use actix_web::{body::Body, HttpResponse, ResponseError};

use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct ServerResponse<T> {
    pub msg: String,
    pub data: Option<T>,
    pub code: ServerCode,
}

impl<T: Serialize> ServerResponse<T> {
    pub fn new(data: Option<T>, msg: &str, code: ServerCode) -> Self {
        ServerResponse {
            msg: msg.to_owned(),
            data,
            code,
        }
    }

    pub fn from_data(data: T, msg: &str, code: ServerCode) -> Self {
        Self::new(Some(data), msg, code)
    }
}

impl ServerResponse<String> {
    pub fn success() -> Self { Self::from_msg("", ServerCode::Success) }

    pub fn from_msg(msg: &str, code: ServerCode) -> Self {
        Self::new(Some("".to_owned()), msg, code)
    }
}

impl<T: Serialize> std::convert::Into<HttpResponse> for ServerResponse<T> {
    fn into(self) -> HttpResponse {
        match serde_json::to_string(&self) {
            Ok(body) => HttpResponse::Ok().body(Body::from(body)),
            Err(e) => {
                let msg = format!("Serial error: {:?}", e);
                ServerError::InternalError(msg).error_response()
            },
        }
    }
}
