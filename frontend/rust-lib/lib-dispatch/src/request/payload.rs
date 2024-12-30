use std::{fmt, fmt::Formatter};

use bytes::Bytes;

#[derive(Clone)]
#[cfg_attr(feature = "use_serde", derive(serde::Serialize))]
pub enum Payload {
  None,
  Bytes(Bytes),
}

impl Payload {
  pub fn to_vec(self) -> Vec<u8> {
    match self {
      Payload::None => vec![],
      Payload::Bytes(bytes) => bytes.to_vec(),
    }
  }
}

impl AsRef<[u8]> for Payload {
  fn as_ref(&self) -> &[u8] {
    match self {
      Payload::None => &[],
      Payload::Bytes(bytes) => bytes.as_ref(),
    }
  }
}

impl std::fmt::Debug for Payload {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    format_payload_print(self, f)
  }
}

impl std::fmt::Display for Payload {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    format_payload_print(self, f)
  }
}

fn format_payload_print(payload: &Payload, f: &mut Formatter<'_>) -> fmt::Result {
  match payload {
    Payload::Bytes(bytes) => f.write_fmt(format_args!("{} bytes", bytes.len())),
    Payload::None => f.write_str("Empty"),
  }
}

impl std::convert::From<String> for Payload {
  fn from(s: String) -> Self {
    Payload::Bytes(Bytes::from(s))
  }
}

impl std::convert::From<&'_ String> for Payload {
  fn from(s: &String) -> Self {
    Payload::Bytes(Bytes::from(s.to_owned()))
  }
}

impl std::convert::From<Bytes> for Payload {
  fn from(bytes: Bytes) -> Self {
    Payload::Bytes(bytes)
  }
}

impl std::convert::From<()> for Payload {
  fn from(_: ()) -> Self {
    Payload::None
  }
}
impl std::convert::From<Vec<u8>> for Payload {
  fn from(bytes: Vec<u8>) -> Self {
    Payload::Bytes(Bytes::from(bytes))
  }
}

impl std::convert::From<&str> for Payload {
  fn from(s: &str) -> Self {
    s.to_string().into()
  }
}
