use std::fmt;
use std::fmt::Display;

use serde::de::{Error, Visitor};
use serde::{Deserialize, Deserializer};
use uuid::Uuid;

use crate::supabase::api::util::SupabaseRealtimeEventBinaryColumnDecoder;
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
}

#[derive(Debug, Deserialize)]
pub(crate) struct UserProfileResponseList(pub Vec<UserProfileResponse>);

#[derive(Deserialize, Clone)]
pub(crate) struct UidResponse {
  #[allow(dead_code)]
  pub uid: i64,
}

#[derive(Debug, Deserialize)]
pub struct RealtimeCollabUpdateEvent {
  pub schema: String,
  pub table: String,
  #[serde(rename = "eventType")]
  pub event_type: String,
  #[serde(rename = "new")]
  pub payload: RealtimeCollabUpdate,
}

impl Display for RealtimeCollabUpdateEvent {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(
      f,
      "schema: {}, table: {}, event_type: {}",
      self.schema, self.table, self.event_type
    )
  }
}

#[derive(Debug, Deserialize)]
pub struct RealtimeCollabUpdate {
  pub oid: String,
  pub uid: i64,
  pub key: i64,
  pub did: String,
  #[serde(deserialize_with = "deserialize_value")]
  pub value: Vec<u8>,
}

pub fn deserialize_value<'de, D>(deserializer: D) -> Result<Vec<u8>, D::Error>
where
  D: Deserializer<'de>,
{
  struct ValueVisitor();

  impl<'de> Visitor<'de> for ValueVisitor {
    type Value = Vec<u8>;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
      formatter.write_str("Expect NodeBody")
    }

    fn visit_str<E>(self, v: &str) -> Result<Self::Value, E>
    where
      E: Error,
    {
      Ok(SupabaseRealtimeEventBinaryColumnDecoder::decode(v).unwrap_or_default())
    }

    fn visit_string<E>(self, v: String) -> Result<Self::Value, E>
    where
      E: Error,
    {
      Ok(SupabaseRealtimeEventBinaryColumnDecoder::decode(v).unwrap_or_default())
    }
  }
  deserializer.deserialize_any(ValueVisitor())
}
