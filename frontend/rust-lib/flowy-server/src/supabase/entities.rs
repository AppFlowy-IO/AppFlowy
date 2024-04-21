use std::fmt;
use std::fmt::Display;

use chrono::{DateTime, Utc};
use serde::Deserialize;
use serde_json::Value;
use uuid::Uuid;

use crate::util::deserialize_null_or_default;

pub enum GetUserProfileParams {
  Uid(i64),
  Uuid(Uuid),
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
  pub latest_workspace_id: String,

  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub encryption_sign: String,

  pub updated_at: DateTime<Utc>,
}

#[derive(Deserialize, Clone)]
pub(crate) struct UidResponse {
  #[allow(dead_code)]
  pub uid: i64,
}

#[derive(Debug, Deserialize)]
pub struct RealtimeEvent {
  pub schema: String,
  pub table: String,
  #[serde(rename = "eventType")]
  pub event_type: String,
  pub new: Value,
}
impl Display for RealtimeEvent {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(
      f,
      "schema: {}, table: {}, event_type: {}",
      self.schema, self.table, self.event_type
    )
  }
}

#[derive(Debug, Deserialize)]
pub struct RealtimeCollabUpdateEvent {
  pub oid: String,
  pub uid: i64,
  pub key: i64,
  pub did: String,
  pub value: String,
  #[serde(default)]
  pub encrypt: i32,
}

#[derive(Debug, Deserialize)]
pub struct RealtimeUserEvent {
  pub uid: i64,
  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub name: String,
  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub email: String,
  #[serde(deserialize_with = "deserialize_null_or_default")]
  pub encryption_sign: String,
}
