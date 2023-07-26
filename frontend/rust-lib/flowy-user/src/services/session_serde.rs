use std::fmt;

use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use chrono::prelude::*;
use serde::de::{Deserializer, MapAccess, Visitor};
use serde::Deserialize;
use serde::Serialize;

use flowy_user_deps::entities::{SignInResponse, UserWorkspace};

#[derive(Debug, Clone, Serialize)]
pub struct Session {
  pub user_id: i64,
  pub user_workspace: UserWorkspace,
}

struct SessionVisitor;
impl<'de> Visitor<'de> for SessionVisitor {
  type Value = Session;

  fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
    formatter.write_str("Session")
  }

  fn visit_map<M>(self, mut map: M) -> Result<Self::Value, M::Error>
  where
    M: MapAccess<'de>,
  {
    let mut user_id = None;
    // For historical reasons, the session used to contain a workspace_id field.
    // This field is no longer used, and is replaced by user_workspace.
    let mut workspace_id = None;
    let mut user_workspace = None;

    while let Some(key) = map.next_key::<String>()? {
      match key.as_str() {
        "user_id" => {
          user_id = Some(map.next_value()?);
        },
        "workspace_id" => {
          workspace_id = Some(map.next_value()?);
        },
        "user_workspace" => {
          user_workspace = Some(map.next_value()?);
        },
        _ => {},
      }
    }
    let user_id = user_id.ok_or(serde::de::Error::missing_field("user_id"))?;
    if user_workspace.is_none() {
      if let Some(workspace_id) = workspace_id {
        user_workspace = Some(UserWorkspace {
          id: workspace_id,
          name: "My Workspace".to_string(),
          created_at: Utc::now(),
          // For historical reasons, the database_storage_id is constructed by the user_id.
          database_storage_id: STANDARD.encode(format!("{}:user:database", user_id)),
        })
      }
    }

    let session = Session {
      user_id,
      user_workspace: user_workspace.ok_or(serde::de::Error::missing_field("user_workspace"))?,
    };

    Ok(session)
  }
}

impl<'de> Deserialize<'de> for Session {
  fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
  where
    D: Deserializer<'de>,
  {
    deserializer.deserialize_any(SessionVisitor)
  }
}

impl std::convert::From<SignInResponse> for Session {
  fn from(resp: SignInResponse) -> Self {
    Session {
      user_id: resp.user_id,
      user_workspace: resp.latest_workspace,
    }
  }
}

impl std::convert::From<Session> for String {
  fn from(session: Session) -> Self {
    match serde_json::to_string(&session) {
      Ok(s) => s,
      Err(e) => {
        tracing::error!("Serialize session to string failed: {:?}", e);
        "".to_string()
      },
    }
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[derive(serde::Serialize)]
  struct OldSession {
    user_id: i64,
    workspace_id: String,
  }

  #[test]
  fn deserialize_user_workspace_from_workspace_id() {
    // For historical reasons, the session used to contain a workspace_id field.
    let old = OldSession {
      user_id: 1,
      workspace_id: uuid::Uuid::new_v4().to_string(),
    };
    let s = serde_json::to_string(&old).unwrap();
    let new = serde_json::from_str::<Session>(&s).unwrap();
    assert_eq!(old.user_id, new.user_id);
    assert_eq!(old.workspace_id, new.user_workspace.id);
  }
}
