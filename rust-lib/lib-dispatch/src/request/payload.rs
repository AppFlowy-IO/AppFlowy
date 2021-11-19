use bytes::Bytes;
use std::{fmt, fmt::Formatter};

pub enum PayloadError {}

// TODO: support stream data
#[derive(Clone, serde::Serialize)]
pub enum Payload {
    None,
    Bytes(Bytes),
}

impl std::fmt::Debug for Payload {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result { format_payload_print(self, f) }
}

impl std::fmt::Display for Payload {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result { format_payload_print(self, f) }
}

fn format_payload_print(payload: &Payload, f: &mut Formatter<'_>) -> fmt::Result {
    match payload {
        Payload::Bytes(bytes) => f.write_fmt(format_args!("{} bytes", bytes.len())),
        Payload::None => f.write_str("Empty"),
    }
}

impl std::convert::Into<Payload> for String {
    fn into(self) -> Payload { Payload::Bytes(Bytes::from(self)) }
}

impl std::convert::Into<Payload> for &'_ String {
    fn into(self) -> Payload { Payload::Bytes(Bytes::from(self.to_owned())) }
}

impl std::convert::Into<Payload> for Bytes {
    fn into(self) -> Payload { Payload::Bytes(self) }
}

impl std::convert::Into<Payload> for () {
    fn into(self) -> Payload { Payload::None }
}

impl std::convert::Into<Payload> for Vec<u8> {
    fn into(self) -> Payload { Payload::Bytes(Bytes::from(self)) }
}

impl std::convert::Into<Payload> for &str {
    fn into(self) -> Payload { self.to_string().into() }
}
