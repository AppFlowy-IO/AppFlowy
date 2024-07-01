use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::session::Session;
use serde_json::{json, Value};
use std::sync::Arc;
use uuid::Uuid;

const MIGRATION_USER_NO_USER_UUID: &str = "migration_user_no_user_uuid";

pub fn migrate_session_with_user_uuid(
  session_cache_key: &str,
  store_preferences: &Arc<KVStorePreferences>,
) -> Option<Session> {
  if !store_preferences.get_bool(MIGRATION_USER_NO_USER_UUID)
    && store_preferences
      .set_bool(MIGRATION_USER_NO_USER_UUID, true)
      .is_ok()
  {
    if let Some(mut value) = store_preferences.get_object::<Value>(session_cache_key) {
      if value.get("user_uuid").is_none() {
        if let Some(map) = value.as_object_mut() {
          map.insert("user_uuid".to_string(), json!(Uuid::new_v4()));
        }
      }

      if let Ok(new_session) = serde_json::from_value::<Session>(value) {
        let _ = store_preferences.set_object(session_cache_key, &new_session);
        return Some(new_session);
      }
    }
  }

  None
}
