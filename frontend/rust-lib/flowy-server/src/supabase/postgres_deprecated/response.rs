use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use thiserror::Error;

use flowy_error::{ErrorCode, FlowyError};

use crate::util::deserialize_null_or_default;

#[derive(Debug, Error, Serialize, Deserialize)]
#[error(
  "PostgrestException(message: {message}, code: {code:?}, details: {details:?}, hint: {hint:?})"
)]
pub struct PostgrestError {
  message: String,
  code: String,
  details: Value,
  hint: Option<String>,
}

impl PostgrestError {
  /// Error code 23505 is a PostgreSQL error code. It signifies a "unique_violation", which occurs
  /// when a certain unique constraint has been violated.
  pub fn is_unique_violation(&self) -> bool {
    self.code == "23505"
  }
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct PostgrestResponse {
  data: Option<String>,
  status: i32,
  count: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub(crate) struct InsertResponse(pub Vec<InsertRecord>);

impl InsertResponse {
  pub(crate) fn first_or_error(&self) -> Result<InsertRecord, FlowyError> {
    if self.0.is_empty() {
      Err(FlowyError::new(
        ErrorCode::UnexpectedEmpty,
        "Insert response contains no records",
      ))
    } else {
      Ok(self.0[0].clone())
    }
  }
}

#[derive(Debug, Deserialize, Clone)]
pub(crate) struct InsertRecord {
  pub(crate) uid: i64,
  #[allow(dead_code)]
  pub(crate) uuid: String,
}

#[derive(Debug, Deserialize, Clone)]
pub(crate) struct UserWorkspace {
  #[allow(dead_code)]
  pub uid: i64,
  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub workspace_name: String,
  pub created_at: DateTime<Utc>,
  pub workspace_id: String,
}

#[derive(Debug, Deserialize)]
pub(crate) struct UserWorkspaceList(pub(crate) Vec<UserWorkspace>);

impl UserWorkspaceList {
  pub(crate) fn into_inner(self) -> Vec<UserWorkspace> {
    self.0
  }
}
