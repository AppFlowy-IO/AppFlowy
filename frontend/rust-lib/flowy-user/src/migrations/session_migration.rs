use crate::manager::UserConfig;
use crate::services::entities::Session;
use flowy_sqlite::kv::StorePreferences;
use flowy_user_deps::entities::Authenticator;
use serde_json::{json, Value};
use std::sync::Arc;
use uuid::Uuid;

pub fn migrate_session_with_user_uuid(
  authenticator: &Authenticator,
  user_config: &UserConfig,
  session: &Arc<parking_lot::RwLock<Option<Session>>>,
  store_preferences: &Arc<StorePreferences>,
) {
  if matches!(authenticator, Authenticator::Local) {
    if let Some(mut value) = store_preferences.get_object::<Value>(&user_config.session_cache_key) {
      if value.get("user_uuid").is_none() {
        value.as_object_mut().map(|map| {
          map.insert("user_uuid".to_string(), json!(Uuid::new_v4()));
        });
      }

      if let Ok(new_session) = serde_json::from_value::<Session>(value) {
        *session.write() = Some(new_session.clone());
        let _ = store_preferences.set_object(&user_config.session_cache_key, &new_session);
      }
    }
  }
}
