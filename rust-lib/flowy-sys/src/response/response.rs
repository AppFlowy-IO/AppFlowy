use crate::{
    error::SystemError,
    request::FlowyRequest,
    response::{data::ResponseData, Responder},
};
use serde::{Deserialize, Serialize};
use serde_with::skip_serializing_none;
use std::{fmt, fmt::Formatter};

#[derive(Clone, Copy, Debug, Serialize, Deserialize)]
pub enum StatusCode {
    Success,
    Error,
}

#[skip_serializing_none]
#[derive(Serialize, Deserialize, Debug)]
pub struct FlowyResponse<T = ResponseData> {
    pub data: T,
    pub status: StatusCode,
    #[serde(skip)]
    pub error: Option<SystemError>,
}

impl FlowyResponse {
    pub fn new(status: StatusCode) -> Self {
        FlowyResponse {
            data: ResponseData::None,
            status,
            error: None,
        }
    }
}

impl std::fmt::Display for FlowyResponse {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match serde_json::to_string(self) {
            Ok(json) => f.write_fmt(format_args!("{:?}", json))?,
            Err(e) => f.write_fmt(format_args!("{:?}", e))?,
        }
        Ok(())
    }
}

impl Responder for FlowyResponse {
    #[inline]
    fn respond_to(self, _: &FlowyRequest) -> FlowyResponse { self }
}
