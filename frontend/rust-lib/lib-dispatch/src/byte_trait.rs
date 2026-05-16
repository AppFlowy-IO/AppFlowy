use bytes::Bytes;

use crate::errors::{DispatchError, InternalError};

// To bytes
pub trait ToBytes {
  fn into_bytes(self) -> Result<Bytes, DispatchError>;
}

#[cfg(feature = "use_protobuf")]
impl<T> ToBytes for T
where
  T: std::convert::TryInto<Bytes, Error = protobuf::ProtobufError>,
{
  fn into_bytes(self) -> Result<Bytes, DispatchError> {
    match self.try_into() {
      Ok(data) => Ok(data),
      Err(e) => Err(
        InternalError::ProtobufError(format!(
          "Serial {:?} to bytes failed:{:?}",
          std::any::type_name::<T>(),
          e
        ))
        .into(),
      ),
    }
  }
}

pub trait AFPluginFromBytes: Sized {
  fn parse_from_bytes(bytes: Bytes) -> Result<Self, DispatchError>;
}

#[cfg(feature = "use_protobuf")]
impl<T> AFPluginFromBytes for T
where
  // // https://stackoverflow.com/questions/62871045/tryfromu8-trait-bound-in-trait
  // T: for<'a> std::convert::TryFrom<&'a Bytes, Error =
  // protobuf::ProtobufError>,
  T: std::convert::TryFrom<Bytes, Error = protobuf::ProtobufError>,
{
  fn parse_from_bytes(bytes: Bytes) -> Result<Self, DispatchError> {
    match T::try_from(bytes) {
      Ok(data) => Ok(data),
      Err(e) => {
        tracing::error!(
          "Parse payload to {} failed with error: {:?}",
          std::any::type_name::<T>(),
          e
        );
        Err(e.into())
      },
    }
  }
}
//
// #[cfg(feature = "use_serde")]
// impl<T> AFPluginFromBytes for T
// where
//     T: serde::de::DeserializeOwned + 'static,
// {
//     fn parse_from_bytes(bytes: Bytes) -> Result<Self, String> {
//         let s = String::from_utf8_lossy(&bytes);
//
//         match serde_json::from_str::<T>(s.as_ref()) {
//             Ok(data) => Ok(data),
//             Err(e) => Err(format!("{:?}", e)),
//         }
//     }
// }
