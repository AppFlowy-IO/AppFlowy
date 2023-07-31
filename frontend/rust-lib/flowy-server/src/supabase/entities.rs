use serde::Deserialize;
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
}

#[derive(Debug, Deserialize)]
pub(crate) struct UserProfileResponseList(pub Vec<UserProfileResponse>);

#[derive(Deserialize, Clone)]
pub(crate) struct UidResponse {
  #[allow(dead_code)]
  pub uid: i64,
}
