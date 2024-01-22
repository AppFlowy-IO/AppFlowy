use flowy_derive::ProtoBuf;
use serde::Serialize;
use std::{fmt, fmt::Formatter};

#[derive(Debug, Clone, ProtoBuf, Serialize)]
pub struct SubscribeObject {
  #[pb(index = 1)]
  pub source: String,

  #[pb(index = 2)]
  pub ty: i32,

  #[pb(index = 3)]
  pub id: String,

  #[pb(index = 4, one_of)]
  pub payload: Option<Vec<u8>>,

  #[pb(index = 5, one_of)]
  pub error: Option<Vec<u8>>,
}

impl std::fmt::Display for SubscribeObject {
  fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
    f.write_str(&format!("{} changed: ", &self.source))?;
    if let Some(payload) = &self.payload {
      f.write_str(&format!("send {} payload", payload.len()))?;
    }

    if let Some(payload) = &self.error {
      f.write_str(&format!("receive {} error", payload.len()))?;
    }

    Ok(())
  }
}

impl std::default::Default for SubscribeObject {
  fn default() -> Self {
    Self {
      source: "".to_string(),
      ty: 0,
      id: "".to_string(),
      payload: None,
      error: None,
    }
  }
}
