use crate::user_manager::manager_history_user::ANON_USER;
use chrono::Utc;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::entities::{Role, UserWorkspace, WorkspaceType};
use flowy_user_pub::session::Session;
use serde::de::{MapAccess, Visitor};
use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;
use std::fmt;
use std::sync::Arc;
use uuid::Uuid;

const MIGRATION_SESSION: &str = "migration_session_key";
pub const SESSION_CACHE_KEY_BACKUP: &str = "session_cache_key_backup";

pub fn migrate_session(
  session_cache_key: &str,
  store_preferences: &Arc<KVStorePreferences>,
) -> Option<Session> {
  if !store_preferences.get_bool_or_default(MIGRATION_SESSION)
    && store_preferences.set_bool(MIGRATION_SESSION, true).is_ok()
  {
    if let Some(anon_session) = store_preferences.get_object::<SessionBackup>(ANON_USER) {
      let new_anon_session = Session {
        user_id: anon_session.user_id,
        user_uuid: anon_session.user_uuid,
        workspace_id: anon_session.user_workspace.id,
      };
      let _ = store_preferences.set_object(ANON_USER, &new_anon_session);
    }

    if let Some(session) = store_preferences.get_object::<SessionBackup>(session_cache_key) {
      let _ = store_preferences.set_object(SESSION_CACHE_KEY_BACKUP, &session);
      let new_session = Session {
        user_id: session.user_id,
        user_uuid: session.user_uuid,
        workspace_id: session.user_workspace.id,
      };
      let _ = store_preferences.set_object(session_cache_key, &new_session);
    }
  }
  store_preferences.get_object::<Session>(session_cache_key)
}

#[derive(Debug, Clone, Serialize)]
struct SessionBackup {
  user_id: i64,
  user_uuid: Uuid,
  user_workspace: UserWorkspace,
}
pub fn get_v0_session_workspace(
  store_preferences: &Arc<KVStorePreferences>,
) -> Option<UserWorkspace> {
  store_preferences
    .get_object::<SessionBackup>(SESSION_CACHE_KEY_BACKUP)
    .map(|v| v.user_workspace)
}

struct SessionVisitor;
impl<'de> Visitor<'de> for SessionVisitor {
  type Value = SessionBackup;

  fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
    formatter.write_str("SessionBackup")
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
    let user_uuid = user_uuid.unwrap_or_else(Uuid::new_v4);
    if user_workspace.is_none() {
      if let Some(workspace_id) = workspace_id {
        user_workspace = Some(UserWorkspace {
          id: workspace_id,
          name: "My Workspace".to_string(),
          created_at: Utc::now(),
          workspace_database_id: Uuid::new_v4().to_string(),
          icon: "".to_owned(),
          member_count: 1,
          role: Some(Role::Owner),
          workspace_type: WorkspaceType::Local,
        })
      }
    }

    let session = SessionBackup {
      user_id,
      user_uuid,
      user_workspace: user_workspace.ok_or(serde::de::Error::missing_field("user_workspace"))?,
    };

    Ok(session)
  }
}

impl<'de> Deserialize<'de> for SessionBackup {
  fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
  where
    D: Deserializer<'de>,
  {
    deserializer.deserialize_any(SessionVisitor)
  }
}
