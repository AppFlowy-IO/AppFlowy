use bytes::{Bytes};

use std::{fmt, fmt::Formatter};

#[derive(Debug, Clone)]
// #[cfg_attr(feature = "use_serde", derive(Serialize, Deserialize))]
pub enum ResponseData {
    Bytes(Vec<u8>),
    None,
}

impl std::fmt::Display for ResponseData {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            ResponseData::Bytes(bytes) => f.write_fmt(format_args!("{} bytes", bytes.len())),
            ResponseData::None => f.write_str("Empty"),
        }
    }
}

impl std::convert::Into<ResponseData> for String {
    fn into(self) -> ResponseData { ResponseData::Bytes(self.into_bytes()) }
}

impl std::convert::Into<ResponseData> for &'_ String {
    fn into(self) -> ResponseData { ResponseData::Bytes(self.to_owned().into_bytes()) }
}

impl std::convert::Into<ResponseData> for Bytes {
    fn into(self) -> ResponseData {
        // Opti(nathan): do not copy the bytes?
        ResponseData::Bytes(self.as_ref().to_vec())
    }
}

impl std::convert::Into<ResponseData> for Vec<u8> {
    fn into(self) -> ResponseData { ResponseData::Bytes(self) }
}

impl std::convert::Into<ResponseData> for &str {
    fn into(self) -> ResponseData { self.to_string().into() }
}
