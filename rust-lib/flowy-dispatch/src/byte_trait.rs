use crate::errors::{DispatchError, InternalError};
use bytes::Bytes;
use protobuf::ProtobufError;

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
            Err(e) => {
                // let system_err: DispatchError = InternalError::new(format!("{:?}",
                // e)).into(); system_err.into()
                // Err(format!("{:?}", e))

                Err(InternalError::ProtobufError(format!("{:?}", e)).into())
            },
        }
    }
}

#[cfg(feature = "use_serde")]
impl<T> ToBytes for T
where
    T: serde::Serialize,
{
    fn into_bytes(self) -> Result<Bytes, DispatchError> {
        match serde_json::to_string(&self.0) {
            Ok(s) => Ok(Bytes::from(s)),
            Err(e) => Err(InternalError::SerializeToBytes(format!("{:?}", e)).into()),
        }
    }
}

// From bytes

pub trait FromBytes: Sized {
    fn parse_from_bytes(bytes: Bytes) -> Result<Self, DispatchError>;
}

#[cfg(feature = "use_protobuf")]
impl<T> FromBytes for T
where
    // https://stackoverflow.com/questions/62871045/tryfromu8-trait-bound-in-trait
    T: for<'a> std::convert::TryFrom<&'a Bytes, Error = protobuf::ProtobufError>,
{
    fn parse_from_bytes(bytes: Bytes) -> Result<Self, DispatchError> {
        let data = T::try_from(&bytes)?;
        Ok(data)
    }
}

#[cfg(feature = "use_serde")]
impl<T> FromBytes for T
where
    T: serde::de::DeserializeOwned + 'static,
{
    fn parse_from_bytes(bytes: Bytes) -> Result<Self, String> {
        let s = String::from_utf8_lossy(&bytes);

        match serde_json::from_str::<T>(s.as_ref()) {
            Ok(data) => Ok(data),
            Err(e) => Err(format!("{:?}", e)),
        }
    }
}
