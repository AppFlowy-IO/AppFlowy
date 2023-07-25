use serde::Deserialize;
use uuid::Uuid;

use crate::supabase::storage_impls::pooler::LATEST_WORKSPACE_ID;
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

impl From<tokio_postgres::Row> for UserProfileResponse {
  fn from(row: tokio_postgres::Row) -> Self {
    let latest_workspace_id: Uuid = row.get(LATEST_WORKSPACE_ID);
    Self {
      uid: row.get("uid"),
      name: row.try_get("name").unwrap_or_default(),
      email: row.try_get("email").unwrap_or_default(),
      latest_workspace_id: latest_workspace_id.to_string(),
    }
  }
}

#[derive(Debug, Deserialize)]
pub(crate) struct UserProfileResponseList(pub Vec<UserProfileResponse>);
