use serde::Deserialize;
use uuid::Uuid;

use crate::supabase::impls::WORKSPACE_ID;
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
  pub workspace_id: String,
}

impl From<tokio_postgres::Row> for UserProfileResponse {
  fn from(row: tokio_postgres::Row) -> Self {
    let workspace_id: Uuid = row.get(WORKSPACE_ID);
    Self {
      uid: row.get("uid"),
      name: row.try_get("name").unwrap_or_default(),
      email: row.try_get("email").unwrap_or_default(),
      workspace_id: workspace_id.to_string(),
    }
  }
}

#[derive(Debug, Deserialize)]
pub(crate) struct UserProfileResponseList(pub Vec<UserProfileResponse>);
