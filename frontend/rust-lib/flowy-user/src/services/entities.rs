use std::fmt;

use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use chrono::prelude::*;
use serde::de::{Deserializer, MapAccess, Visitor};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use flowy_user_deps::entities::{AuthResponse, UserProfile, UserWorkspace};
use flowy_user_deps::entities::{Authenticator, UserAuthResponse};

use crate::entities::AuthenticatorPB;
use crate::migrations::MigrationUser;

#[derive(Debug, Clone, Serialize)]
pub struct Session {
  pub user_id: i64,
  pub user_uuid: Uuid,
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
    let mut user_uuid = None;
    // For historical reasons, the session used to contain a workspace_id field.
    // This field is no longer used, and is replaced by user_workspace.
    let mut workspace_id = None;
    let mut user_workspace = None;

    while let Some(key) = map.next_key::<String>()? {
      match key.as_str() {
        "user_id" => {
          user_id = Some(map.next_value()?);
        },
        "user_uuid" => {
          user_uuid = Some(map.next_value()?);
        },
        "workspace_id" => {
          workspace_id = Some(map.next_value()?);
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
    let user_uuid = user_uuid.ok_or(serde::de::Error::missing_field("user_uuid"))?;
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
      user_uuid,
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
      user_uuid: *value.user_uuid(),
      user_workspace: value.latest_workspace().clone(),
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

impl From<AuthenticatorPB> for Authenticator {
  fn from(pb: AuthenticatorPB) -> Self {
    match pb {
      AuthenticatorPB::Supabase => Authenticator::Supabase,
      AuthenticatorPB::Local => Authenticator::Local,
      AuthenticatorPB::AppFlowyCloud => Authenticator::AppFlowyCloud,
    }
  }
}

impl From<Authenticator> for AuthenticatorPB {
  fn from(auth_type: Authenticator) -> Self {
    match auth_type {
      Authenticator::Supabase => AuthenticatorPB::Supabase,
      Authenticator::Local => AuthenticatorPB::Local,
      Authenticator::AppFlowyCloud => AuthenticatorPB::AppFlowyCloud,
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
  pub auth_type: Authenticator,
  pub sign_in_timestamp: i64,
  pub storage_path: String,
  #[serde(default)]
  pub device_id: String,
}
const DEFAULT_AUTH_TYPE: fn() -> Authenticator = || Authenticator::Local;

#[derive(Clone)]
pub(crate) struct ResumableSignUp {
  pub user_profile: UserProfile,
  pub response: AuthResponse,
  pub authenticator: Authenticator,
  pub migration_user: Option<MigrationUser>,
}
