use bytes::Bytes;

// To bytes
pub trait ToBytes {
    fn into_bytes(self) -> Result<Bytes, String>;
}

#[cfg(feature = "use_protobuf")]
impl<T> ToBytes for T
where
    T: std::convert::TryInto<Bytes, Error = String>,
{
    fn into_bytes(self) -> Result<Bytes, String> { self.try_into() }
}

#[cfg(feature = "use_serde")]
impl<T> ToBytes for T
where
    T: serde::Serialize,
{
    fn into_bytes(self) -> Result<Bytes, String> {
        match serde_json::to_string(&self.0) {
            Ok(s) => Ok(Bytes::from(s)),
            Err(e) => Err(format!("{:?}", e)),
        }
    }
}

// From bytes

pub trait FromBytes: Sized {
    fn parse_from_bytes(bytes: Bytes) -> Result<Self, String>;
}

#[cfg(feature = "use_protobuf")]
impl<T> FromBytes for T
where
    // https://stackoverflow.com/questions/62871045/tryfromu8-trait-bound-in-trait
    T: for<'a> std::convert::TryFrom<&'a Bytes, Error = String>,
{
    fn parse_from_bytes(bytes: Bytes) -> Result<Self, String> { T::try_from(&bytes) }
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
