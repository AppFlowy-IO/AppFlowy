use std::fmt;

use bytes::Bytes;
use serde::{Deserialize, Serialize};

use flowy_error::ErrorCode;

#[derive(Debug, Serialize, Deserialize)]
pub struct HttpResponse {
  pub data: Bytes,
  #[serde(skip_serializing_if = "Option::is_none")]
  pub error: Option<HttpError>,
}

#[derive(thiserror::Error, Debug, Serialize, Deserialize, Clone)]
pub struct HttpError {
  pub code: ErrorCode,
  pub msg: String,
}

impl HttpError {
  #[allow(dead_code)]
  pub fn is_unauthorized(&self) -> bool {
    self.code == ErrorCode::UserUnauthorized
  }
}

impl fmt::Display for HttpError {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(f, "{:?}: {}", self.code, self.msg)
  }
}
