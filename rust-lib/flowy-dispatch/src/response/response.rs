use crate::{
    byte_trait::FromBytes,
    data::Data,
    errors::DispatchError,
    request::{EventRequest, Payload},
    response::Responder,
};
use derivative::*;
use std::{convert::TryFrom, fmt, fmt::Formatter};

#[derive(Clone, Debug, Eq, PartialEq, serde::Serialize)]
pub enum StatusCode {
    Ok       = 0,
    Err      = 1,
    Internal = 2,
}

// serde user guide: https://serde.rs/field-attrs.html
#[derive(Debug, Clone, serde::Serialize, Derivative)]
pub struct EventResponse {
    #[derivative(Debug = "ignore")]
    pub payload: Payload,
    pub status_code: StatusCode,
}

impl EventResponse {
    pub fn new(status_code: StatusCode) -> Self {
        EventResponse {
            payload: Payload::None,
            status_code,
        }
    }

    pub fn parse<T, E>(self) -> Result<Result<T, E>, DispatchError>
    where
        T: FromBytes,
        E: FromBytes,
    {
        match self.status_code {
            StatusCode::Ok => {
                let data = <Data<T>>::try_from(self.payload)?;
                Ok(Ok(data.into_inner()))
            },
            StatusCode::Err | StatusCode::Internal => {
                let err = <Data<E>>::try_from(self.payload)?;
                Ok(Err(err.into_inner()))
            },
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

        Ok(())
    }
}

impl Responder for EventResponse {
    #[inline]
    fn respond_to(self, _: &EventRequest) -> EventResponse { self }
}

pub type DataResult<T, E> = std::result::Result<Data<T>, E>;

pub fn data_result<T, E>(data: T) -> Result<Data<T>, E>
where
    E: Into<DispatchError>,
{
    Ok(Data(data))
}
