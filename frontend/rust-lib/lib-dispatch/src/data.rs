use std::fmt::{Debug, Formatter};
use std::ops;

use bytes::Bytes;
use validator::{Validate, ValidationErrors};

use crate::{
  byte_trait::*,
  errors::{DispatchError, InternalError},
  request::{unexpected_none_payload, AFPluginEventRequest, FromAFPluginRequest, Payload},
  response::{AFPluginEventResponse, AFPluginResponder, ResponseBuilder},
  util::ready::{ready, Ready},
};

pub trait AFPluginDataValidator {
  fn validate(self) -> Result<Self, ValidationErrors>
  where
    Self: Sized;
}

pub struct AFPluginData<T>(pub T);

impl<T> AFPluginData<T> {
  pub fn into_inner(self) -> T {
    self.0
  }
}

impl<T> AFPluginData<T>
where
  T: Validate,
{
  pub fn try_into_inner(self) -> Result<T, ValidationErrors> {
    self.0.validate()?;
    Ok(self.0)
  }
}

impl<T> ops::Deref for AFPluginData<T> {
  type Target = T;

  fn deref(&self) -> &T {
    &self.0
  }
}

impl<T> AFPluginDataValidator for AFPluginData<T>
where
  T: validator::Validate,
{
  fn validate(self) -> Result<Self, ValidationErrors> {
    self.0.validate()?;
    Ok(self)
  }
}

impl<T> ops::DerefMut for AFPluginData<T> {
  fn deref_mut(&mut self) -> &mut T {
    &mut self.0
  }
}

impl<T> FromAFPluginRequest for AFPluginData<T>
where
  T: AFPluginFromBytes + 'static,
{
  type Error = DispatchError;
  type Future = Ready<Result<Self, DispatchError>>;

  #[inline]
  fn from_request(req: &AFPluginEventRequest, payload: &mut Payload) -> Self::Future {
    match payload {
      Payload::None => ready(Err(unexpected_none_payload(req))),
      Payload::Bytes(bytes) => match T::parse_from_bytes(bytes.clone()) {
        Ok(data) => ready(Ok(AFPluginData(data))),
        Err(e) => ready(Err(
          InternalError::DeserializeFromBytes(format!("{}", e)).into(),
        )),
      },
    }
  }
}

impl<T> AFPluginResponder for AFPluginData<T>
where
  T: ToBytes,
{
  fn respond_to(self, _request: &AFPluginEventRequest) -> AFPluginEventResponse {
    match self.into_inner().into_bytes() {
      Ok(bytes) => {
        tracing::trace!(
          "Serialize Data: {:?} to event response",
          std::any::type_name::<T>()
        );
        ResponseBuilder::Ok().data(bytes).build()
      },
      Err(e) => e.into(),
    }
  }
}

impl<T> std::convert::TryFrom<&Payload> for AFPluginData<T>
where
  T: AFPluginFromBytes,
{
  type Error = DispatchError;
  fn try_from(payload: &Payload) -> Result<AFPluginData<T>, Self::Error> {
    parse_payload(payload)
  }
}

impl<T> std::convert::TryFrom<Payload> for AFPluginData<T>
where
  T: AFPluginFromBytes,
{
  type Error = DispatchError;
  fn try_from(payload: Payload) -> Result<AFPluginData<T>, Self::Error> {
    parse_payload(&payload)
  }
}

fn parse_payload<T>(payload: &Payload) -> Result<AFPluginData<T>, DispatchError>
where
  T: AFPluginFromBytes,
{
  match payload {
    Payload::None => Err(
      InternalError::UnexpectedNone(format!(
        "Parse fail, expected payload:{:?}",
        std::any::type_name::<T>()
      ))
      .into(),
    ),
    Payload::Bytes(bytes) => {
      let data = T::parse_from_bytes(bytes.clone())?;
      Ok(AFPluginData(data))
    },
  }
}

impl<T> std::convert::TryInto<Payload> for AFPluginData<T>
where
  T: ToBytes,
{
  type Error = DispatchError;

  fn try_into(self) -> Result<Payload, Self::Error> {
    let inner = self.into_inner();
    let bytes = inner.into_bytes()?;
    Ok(Payload::Bytes(bytes))
  }
}

impl ToBytes for AFPluginData<String> {
  fn into_bytes(self) -> Result<Bytes, DispatchError> {
    Ok(Bytes::from(self.0))
  }
}

impl<T> Debug for AFPluginData<T>
where
  T: Debug,
{
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    self.0.fmt(f)
  }
}
