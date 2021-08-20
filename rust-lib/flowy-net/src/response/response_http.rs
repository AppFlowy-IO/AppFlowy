use crate::{errors::ServerError, response::*};
use actix_web::{body::Body, error::ResponseError, HttpResponse};
use serde::Serialize;

impl ResponseError for ServerError {
    fn error_response(&self) -> HttpResponse {
        match self {
            ServerError::InternalError(msg) => {
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
