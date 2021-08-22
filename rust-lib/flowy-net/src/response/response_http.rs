use crate::response::*;
use actix_web::{body::Body, error::ResponseError, BaseHttpResponse, HttpResponse};
use reqwest::StatusCode;
use serde::Serialize;

impl ResponseError for ServerError {
    fn error_response(&self) -> HttpResponse {
        let response: FlowyResponse = self.into();
        response.into()
    }
}
impl std::convert::Into<HttpResponse> for FlowyResponse {
    fn into(self) -> HttpResponse { HttpResponse::Ok().json(self) }
}
