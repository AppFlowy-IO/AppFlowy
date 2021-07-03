use crate::{
    error::SystemError,
    request::EventRequest,
    response::{data::ResponseData, Responder},
};

use crate::request::Data;

use std::{fmt, fmt::Formatter};

#[derive(Clone, Debug, Eq, PartialEq)]
// #[cfg_attr(feature = "use_serde", derive(Serialize, Deserialize))]
pub enum StatusCode {
    Ok  = 0,
    Err = 1,
}

// serde user guide: https://serde.rs/field-attrs.html
#[derive(Debug, Clone)]
// #[cfg_attr(feature = "use_serde", derive(Serialize))]
pub struct EventResponse {
    pub data: ResponseData,
    pub status: StatusCode,
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
        f.write_fmt(format_args!("Status_Code: {:?}", self.status))?;

        match &self.data {
            ResponseData::Bytes(b) => f.write_fmt(format_args!("Data: {} bytes", b.len()))?,
            ResponseData::None => f.write_fmt(format_args!("Data: Empty"))?,
        }
        match &self.error {
            Some(e) => f.write_fmt(format_args!("Error: {:?}", e))?,
            None => {},
        }

        Ok(())
    }
}

impl Responder for EventResponse {
    #[inline]
    fn respond_to(self, _: &EventRequest) -> EventResponse { self }
}

#[cfg(feature = "use_serde")]
fn serialize_error<S>(error: &Option<SystemError>, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    match error {
        Some(e) => serializer.serialize_str(&format!("{:?}", e)),
        None => serializer.serialize_str(""),
    }
}

#[cfg(feature = "use_serde")]
fn serialize_data<S>(data: &ResponseData, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    match data {
        ResponseData::Bytes(bytes) => serializer.serialize_str(&format!("{} bytes", bytes.len())),
        ResponseData::None => serializer.serialize_str(""),
    }
}

pub fn response_ok<T, E>(data: T) -> Result<Data<T>, E>
where
    E: Into<SystemError>,
{
    Ok(Data(data))
}
