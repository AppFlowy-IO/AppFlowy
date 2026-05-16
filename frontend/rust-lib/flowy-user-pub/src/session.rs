use crate::entities::UserAuthResponse;
use serde::{Deserialize, Serialize};
use std::fmt;
use std::fmt::Display;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Session {
  pub user_id: i64,
  pub user_uuid: Uuid,
  pub workspace_id: String,
}

impl Display for Session {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    write!(
      f,
      "user_id: {}, user_workspace: {}",
      self.user_id, self.workspace_id,
    )
  }
}

impl<T> From<&T> for Session
where
  T: UserAuthResponse,
{
  fn from(value: &T) -> Self {
    Self {
      user_id: value.user_id(),
      user_uuid: *value.user_uuid(),
      workspace_id: value.latest_workspace().clone().id,
    }
  }
}

impl std::convert::From<Session> for String {
  fn from(session: Session) -> Self {
    serde_json::to_string(&session).unwrap_or_else(|e| {
      tracing::error!("Serialize session to string failed: {:?}", e);
      "".to_string()
    })
  }
}
