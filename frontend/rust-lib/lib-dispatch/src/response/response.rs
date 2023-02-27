use crate::{
  byte_trait::AFPluginFromBytes,
  data::AFPluginData,
  errors::DispatchError,
  request::{AFPluginEventRequest, Payload},
  response::AFPluginResponder,
};
use derivative::*;
use std::{convert::TryFrom, fmt, fmt::Formatter};

#[derive(Clone, Debug, Eq, PartialEq)]
#[cfg_attr(feature = "use_serde", derive(serde_repr::Serialize_repr))]
#[repr(u8)]
pub enum StatusCode {
  Ok = 0,
  Err = 1,
}

// serde user guide: https://serde.rs/field-attrs.html
#[derive(Debug, Clone, Derivative)]
#[cfg_attr(feature = "use_serde", derive(serde::Serialize))]
pub struct AFPluginEventResponse {
  #[derivative(Debug = "ignore")]
  pub payload: Payload,
  pub status_code: StatusCode,
}

impl AFPluginEventResponse {
  pub fn new(status_code: StatusCode) -> Self {
    AFPluginEventResponse {
      payload: Payload::None,
      status_code,
    }
  }

  pub fn parse<T, E>(self) -> Result<Result<T, E>, DispatchError>
  where
    T: AFPluginFromBytes,
    E: AFPluginFromBytes,
  {
    match self.status_code {
      StatusCode::Ok => {
        let data = <AFPluginData<T>>::try_from(self.payload)?;
        Ok(Ok(data.into_inner()))
      },
      StatusCode::Err => {
        let err = <AFPluginData<E>>::try_from(self.payload)?;
        Ok(Err(err.into_inner()))
      },
    }
  }
}

impl std::fmt::Display for AFPluginEventResponse {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    f.write_fmt(format_args!("Status_Code: {:?}", self.status_code))?;

    match &self.payload {
      Payload::Bytes(b) => f.write_fmt(format_args!("Data: {} bytes", b.len()))?,
      Payload::None => f.write_fmt(format_args!("Data: Empty"))?,
    }

    Ok(())
  }
}

impl AFPluginResponder for AFPluginEventResponse {
  #[inline]
  fn respond_to(self, _: &AFPluginEventRequest) -> AFPluginEventResponse {
    self
  }
}

pub type DataResult<T, E> = std::result::Result<AFPluginData<T>, E>;

pub fn data_result_ok<T, E>(data: T) -> Result<AFPluginData<T>, E>
where
  E: Into<DispatchError>,
{
  Ok(AFPluginData(data))
}
