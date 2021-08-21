use crate::response::*;
use actix_web::{body::Body, error::ResponseError, BaseHttpResponse, HttpResponse};
use serde::Serialize;

impl ServerError {
    fn http_response(&self) -> HttpResponse {
        let resp: FlowyResponse<String> = self.into();
        HttpResponse::Ok().json(resp)
    }
}

impl ResponseError for ServerError {
    fn error_response(&self) -> HttpResponse { self.http_response().into() }
}

impl<T: Serialize> std::convert::Into<HttpResponse> for FlowyResponse<T> {
    fn into(self) -> HttpResponse {
        match serde_json::to_string(&self) {
            Ok(body) => HttpResponse::Ok().body(Body::from(body)),
            Err(e) => {
                let msg = format!("Serial error: {:?}", e);
                ServerError {
                    code: ServerCode::SerdeError,
                    msg,
                }
                .error_response()
            },
        }
    }
}
