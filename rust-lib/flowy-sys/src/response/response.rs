use crate::{
    error::SystemError,
    request::EventRequest,
    response::{data::ResponseData, Responder},
};
use serde::{Deserialize, Serialize, Serializer};

use std::{fmt, fmt::Formatter};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum StatusCode {
    Ok,
    Err,
}

// serde user guide: https://serde.rs/field-attrs.html
#[derive(Serialize, Debug, Clone)]
pub struct EventResponse {
    #[serde(serialize_with = "serialize_data")]
    pub data: ResponseData,
    pub status: StatusCode,
    #[serde(serialize_with = "serialize_error")]
    pub error: Option<SystemError>,
}

impl EventResponse {
    pub fn new(status: StatusCode) -> Self {
        EventResponse {
            data: ResponseData::None,
            status,
            error: None,
        }
    }
}

impl std::fmt::Display for EventResponse {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match serde_json::to_string(self) {
            Ok(json) => f.write_fmt(format_args!("{:?}", json))?,
            Err(e) => f.write_fmt(format_args!("{:?}", e))?,
        }
        Ok(())
    }
}

impl Responder for EventResponse {
    #[inline]
    fn respond_to(self, _: &EventRequest) -> EventResponse { self }
}

fn serialize_error<S>(error: &Option<SystemError>, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    match error {
        Some(e) => serializer.serialize_str(&format!("{:?}", e)),
        None => serializer.serialize_str(""),
    }
}

fn serialize_data<S>(data: &ResponseData, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    match data {
        ResponseData::Bytes(bytes) => serializer.serialize_str(&format!("{} bytes", bytes.len())),
        ResponseData::None => serializer.serialize_str(""),
    }
}
