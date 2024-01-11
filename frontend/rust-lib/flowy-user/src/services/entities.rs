use base64::alphabet::URL_SAFE;
use std::path::PathBuf;
use std::{fmt, fs};

use base64::engine::general_purpose::{PAD, STANDARD};
use base64::engine::GeneralPurpose;
use base64::Engine;
use chrono::prelude::*;
use serde::de::{Deserializer, MapAccess, Visitor};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use flowy_user_pub::entities::{AuthResponse, UserProfile, UserWorkspace};
use flowy_user_pub::entities::{Authenticator, UserAuthResponse};

use crate::entities::AuthenticatorPB;
use crate::migrations::MigrationUser;
use crate::services::db::UserDBPath;

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
          database_view_tracker_id: STANDARD.encode(format!("{}:user:database", user_id)),
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

#[derive(Clone)]
pub(crate) struct ResumableSignUp {
  pub user_profile: UserProfile,
  pub response: AuthResponse,
  pub authenticator: Authenticator,
  pub migration_user: Option<MigrationUser>,
}

pub const URL_SAFE_ENGINE: GeneralPurpose = GeneralPurpose::new(&URL_SAFE, PAD);
pub struct UserConfig {
  /// Used to store the user data
  pub storage_path: String,
  /// application_path is the path of the application binary. By default, the
  /// storage_path is the same as the application_path. However, when the user
  /// choose a custom path for the user data, the storage_path will be different from
  /// the application_path.
  pub application_path: String,
  pub device_id: String,
  /// Used as the key of `Session` when saving session information to KV.
  pub(crate) session_cache_key: String,
}

impl UserConfig {
  /// The `root_dir` represents as the root of the user folders. It must be unique for each
  /// users.
  pub fn new(name: &str, storage_path: &str, application_path: &str, device_id: &str) -> Self {
    let session_cache_key = format!("{}_session_cache", name);
    Self {
      storage_path: storage_path.to_owned(),
      application_path: application_path.to_owned(),
      session_cache_key,
      device_id: device_id.to_owned(),
    }
  }

  /// Returns bool whether the user choose a custom path for the user data.
  pub fn is_custom_storage_path(&self) -> bool {
    !self.storage_path.contains(&self.application_path)
  }
}

#[derive(Clone)]
pub struct UserPaths {
  root: String,
}

impl UserPaths {
  pub fn new(root: String) -> Self {
    Self { root }
  }

  /// Returns the path to the user's data directory.
  pub(crate) fn user_data_dir(&self, uid: i64) -> String {
    format!("{}/{}", self.root, uid)
  }
}

impl UserDBPath for UserPaths {
  fn sqlite_db_path(&self, uid: i64) -> PathBuf {
    PathBuf::from(self.user_data_dir(uid))
  }

  fn collab_db_path(&self, uid: i64) -> PathBuf {
    let mut path = PathBuf::from(self.user_data_dir(uid));
    path.push("collab_db");
    path
  }

  fn collab_db_history(&self, uid: i64, create_if_not_exist: bool) -> std::io::Result<PathBuf> {
    let path = PathBuf::from(self.user_data_dir(uid)).join("collab_db_history");
    if !path.exists() && create_if_not_exist {
      fs::create_dir_all(&path)?;
    }
    Ok(path)
  }
}
