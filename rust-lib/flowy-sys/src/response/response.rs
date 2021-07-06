use crate::{
    data::Data,
    error::SystemError,
    request::{EventRequest, Payload},
    response::Responder,
};
use std::{fmt, fmt::Formatter};

#[derive(Clone, Debug, Eq, PartialEq, serde::Serialize)]
pub enum StatusCode {
    Ok  = 0,
    Err = 1,
}

// serde user guide: https://serde.rs/field-attrs.html
#[derive(Debug, Clone, serde::Serialize)]
pub struct EventResponse {
    pub payload: Payload,
    pub status_code: StatusCode,
    pub error: Option<SystemError>,
}

impl EventResponse {
    pub fn new(status_code: StatusCode) -> Self {
        EventResponse {
            payload: Payload::None,
            status_code,
            error: None,
        }
    }
}

impl std::fmt::Display for EventResponse {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        f.write_fmt(format_args!("Status_Code: {:?}", self.status_code))?;

        match &self.payload {
            Payload::Bytes(b) => f.write_fmt(format_args!("Data: {} bytes", b.len()))?,
            Payload::None => f.write_fmt(format_args!("Data: Empty"))?,
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

pub type ResponseResult<T, E> = std::result::Result<Data<T>, E>;

pub fn response_ok<T, E>(data: T) -> Result<Data<T>, E>
where
    E: Into<SystemError>,
{
    Ok(Data(data))
}
