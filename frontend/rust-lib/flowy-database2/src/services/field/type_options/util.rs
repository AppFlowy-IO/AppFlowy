use bytes::Bytes;
use protobuf::ProtobufError;
use std::fmt::Display;

#[derive(Default, Debug, Clone)]
pub struct ProtobufStr(pub String);
impl std::ops::Deref for ProtobufStr {
  type Target = String;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

impl std::ops::DerefMut for ProtobufStr {
  fn deref_mut(&mut self) -> &mut Self::Target {
    &mut self.0
  }
}

impl std::convert::From<String> for ProtobufStr {
  fn from(s: String) -> Self {
    Self(s)
  }
}

impl Display for ProtobufStr {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    write!(f, "{}", self.0.clone())
  }
}

impl std::convert::TryFrom<ProtobufStr> for Bytes {
  type Error = ProtobufError;

  fn try_from(value: ProtobufStr) -> Result<Self, Self::Error> {
    Ok(Bytes::from(value.0))
  }
}

impl AsRef<[u8]> for ProtobufStr {
  fn as_ref(&self) -> &[u8] {
    self.0.as_ref()
  }
}
impl AsRef<str> for ProtobufStr {
  fn as_ref(&self) -> &str {
    self.0.as_str()
  }
}
