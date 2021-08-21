use crate::{errors::NetworkError, response::*};
use actix_web::{body::Body, error::ResponseError, BaseHttpResponse, HttpResponse};
use serde::Serialize;

impl NetworkError {
    fn http_response(&self) -> HttpResponse {
        match self {
            NetworkError::InternalError(msg) => {
                let resp = FlowyResponse::from_msg(&msg, ServerCode::InternalError);
                HttpResponse::InternalServerError().json(resp)
            },
            NetworkError::BadRequest(ref resp) => HttpResponse::BadRequest().json(resp),
            NetworkError::Unauthorized => {
                let resp = FlowyResponse::from_msg("Unauthorized", ServerCode::Unauthorized);
                HttpResponse::Unauthorized().json(resp)
            },
        }
    }
}

impl ResponseError for NetworkError {
    fn error_response(&self) -> HttpResponse { self.http_response().into() }
}

impl<T: Serialize> std::convert::Into<HttpResponse> for FlowyResponse<T> {
    fn into(self) -> HttpResponse {
        match serde_json::to_string(&self) {
            Ok(body) => HttpResponse::Ok().body(Body::from(body)),
            Err(e) => {
                let msg = format!("Serial error: {:?}", e);
                NetworkError::InternalError(msg).error_response()
            },
        }
    }
}
