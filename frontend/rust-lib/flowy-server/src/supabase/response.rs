use chrono::{DateTime, Utc};
use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;
use thiserror::Error;

use flowy_error::{ErrorCode, FlowyError};

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

#[allow(dead_code)]
#[derive(Debug, Deserialize, Clone)]
pub(crate) struct UserProfileResponse {
  pub uid: i64,
  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub name: String,

  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub email: String,

  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub workspace_id: String,
}

#[derive(Debug, Deserialize)]
pub(crate) struct UserProfileResponseList(pub Vec<UserProfileResponse>);

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

/// Handles the case where the value is null. If the value is null, return the default value of the
/// type. Otherwise, deserialize the value.
fn deserialize_null_or_default<'de, D, T>(deserializer: D) -> Result<T, D::Error>
where
  T: Default + Deserialize<'de>,
  D: Deserializer<'de>,
{
  let opt = Option::deserialize(deserializer)?;
  Ok(opt.unwrap_or_default())
}
