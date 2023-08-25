use std::fmt;

use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use chrono::prelude::*;
use serde::de::{Deserializer, MapAccess, Visitor};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use flowy_user_deps::entities::{AuthType, UserAuthResponse};
use flowy_user_deps::entities::{SignUpResponse, UserProfile, UserWorkspace};

use crate::entities::AuthTypePB;
use crate::migrations::MigrationUser;

#[derive(Debug, Clone, Serialize)]
pub struct Session {
  pub user_id: i64,
  pub device_id: String,
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
    let mut device_id = "phantom".to_string();
    let mut user_workspace = None;

    while let Some(key) = map.next_key::<String>()? {
      match key.as_str() {
        "user_id" => {
          user_id = Some(map.next_value()?);
        },
        "workspace_id" => {
          workspace_id = Some(map.next_value()?);
        },
        "device_id" => {
          device_id = map.next_value()?;
        },
        "user_workspace" => {
          user_workspace = Some(map.next_value()?);
        },
        _ => {
          let _ = map.next_value::<Value>();
        },
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
      device_id,
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

impl<T> From<&T> for Session
where
  T: UserAuthResponse,
{
  fn from(value: &T) -> Self {
    Self {
      user_id: value.user_id(),
      device_id: value.device_id().to_string(),
      user_workspace: value.latest_workspace().clone(),
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
  use serde_json::json;

  use super::*;

  #[derive(serde::Serialize)]
  struct OldSession {
    user_id: i64,
    workspace_id: String,
    name: String,
  }

  #[test]
  fn deserialize_user_workspace_from_workspace_id() {
    // For historical reasons, the session used to contain a workspace_id field.
    let old = OldSession {
      user_id: 223238635422486528,
      workspace_id: "f58f5492-ee0a-4a9f-8cf1-dacb459a55f6".to_string(),
      name: "Me".to_string(),
    };
    let s = serde_json::to_string(&old).unwrap();
    let new = serde_json::from_str::<Session>(&s).unwrap();
    assert_eq!(old.user_id, new.user_id);
    assert_eq!(old.workspace_id, new.user_workspace.id);

    let json = json!({
      "user_id": 2232386,
      "workspace_id": "f58f5492-ee0a-4a9f-8cf1-dacb459a55f6",
      "name": "Me",
      "token": null,
      "email": "0085bfda-85fa-4611-bfbe-25d5a1229f44@appflowy.io"
    });
    let new = serde_json::from_value::<Session>(json).unwrap();
    assert_eq!(new.user_id, 2232386);
    assert_eq!(
      new.user_workspace.id,
      "f58f5492-ee0a-4a9f-8cf1-dacb459a55f6"
    );
  }
}

impl From<AuthTypePB> for AuthType {
  fn from(pb: AuthTypePB) -> Self {
    match pb {
      AuthTypePB::Supabase => AuthType::Supabase,
      AuthTypePB::Local => AuthType::Local,
      AuthTypePB::SelfHosted => AuthType::SelfHosted,
    }
  }
}

impl From<AuthType> for AuthTypePB {
  fn from(auth_type: AuthType) -> Self {
    match auth_type {
      AuthType::Supabase => AuthTypePB::Supabase,
      AuthType::Local => AuthTypePB::Local,
      AuthType::SelfHosted => AuthTypePB::SelfHosted,
    }
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HistoricalUsers {
  pub(crate) users: Vec<HistoricalUser>,
}

impl HistoricalUsers {
  pub fn add_user(&mut self, new_user: HistoricalUser) {
    self.users.retain(|user| user.user_id != new_user.user_id);
    self.users.push(new_user);
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HistoricalUser {
  pub user_id: i64,
  #[serde(default = "flowy_user_deps::DEFAULT_USER_NAME")]
  pub user_name: String,
  #[serde(default = "DEFAULT_AUTH_TYPE")]
  pub auth_type: AuthType,
  pub sign_in_timestamp: i64,
  pub storage_path: String,
  #[serde(default)]
  pub device_id: String,
}
const DEFAULT_AUTH_TYPE: fn() -> AuthType = || AuthType::Local;

#[derive(Clone)]
pub(crate) struct ResumableSignUp {
  pub user_profile: UserProfile,
  pub response: SignUpResponse,
  pub auth_type: AuthType,
  pub migration_user: Option<MigrationUser>,
}
