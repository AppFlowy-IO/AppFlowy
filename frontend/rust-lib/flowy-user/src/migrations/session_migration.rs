use std::sync::Arc;

use serde_json::{json, Value};
use uuid::Uuid;

use flowy_sqlite::kv::StorePreferences;

use crate::manager::UserConfig;
use crate::services::entities::Session;

const MIGRATION_USER_NO_USER_UUID: &str = "migration_user_no_user_uuid";

pub fn migrate_session_with_user_uuid(
  user_config: &UserConfig,
  session: &Arc<parking_lot::RwLock<Option<Session>>>,
  store_preferences: &Arc<StorePreferences>,
) {
  if !store_preferences.get_bool(MIGRATION_USER_NO_USER_UUID)
    && store_preferences
      .set_bool(MIGRATION_USER_NO_USER_UUID, true)
      .is_ok()
  {
    if let Some(mut value) = store_preferences.get_object::<Value>(&user_config.session_cache_key) {
      if value.get("user_uuid").is_none() {
        if let Some(map) = value.as_object_mut() {
          map.insert("user_uuid".to_string(), json!(Uuid::new_v4()));
        }
      }

      if let Ok(new_session) = serde_json::from_value::<Session>(value) {
        *session.write() = Some(new_session.clone());
        let _ = store_preferences.set_object(&user_config.session_cache_key, &new_session);
      }
    }
  }
}
