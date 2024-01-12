use std::sync::Arc;

use flowy_encrypt::generate_encryption_secret;
use flowy_error::FlowyResult;
use flowy_sqlite::kv::StorePreferences;
use flowy_user_pub::cloud::UserCloudConfig;

const CLOUD_CONFIG_KEY: &str = "af_user_cloud_config";

fn generate_cloud_config(uid: i64, store_preference: &Arc<StorePreferences>) -> UserCloudConfig {
  let config = UserCloudConfig::new(generate_encryption_secret());
  let key = cache_key_for_cloud_config(uid);
  store_preference.set_object(&key, config.clone()).unwrap();
  config
}

pub fn save_cloud_config(
  uid: i64,
  store_preference: &Arc<StorePreferences>,
  config: UserCloudConfig,
) -> FlowyResult<()> {
  tracing::info!("save user:{} cloud config: {}", uid, config);
  let key = cache_key_for_cloud_config(uid);
  store_preference.set_object(&key, config)?;
  Ok(())
}

fn cache_key_for_cloud_config(uid: i64) -> String {
  format!("{}:{}", CLOUD_CONFIG_KEY, uid)
}

pub fn get_cloud_config(
  uid: i64,
  store_preference: &Arc<StorePreferences>,
) -> Option<UserCloudConfig> {
  let key = cache_key_for_cloud_config(uid);
  store_preference.get_object::<UserCloudConfig>(&key)
}

pub fn get_or_create_cloud_config(
  uid: i64,
  store_preferences: &Arc<StorePreferences>,
) -> UserCloudConfig {
  let key = cache_key_for_cloud_config(uid);
  store_preferences
    .get_object::<UserCloudConfig>(&key)
    .unwrap_or_else(|| generate_cloud_config(uid, store_preferences))
}

pub fn get_encrypt_secret(uid: i64, store_preference: &Arc<StorePreferences>) -> Option<String> {
  let key = cache_key_for_cloud_config(uid);
  store_preference
    .get_object::<UserCloudConfig>(&key)
    .map(|config| config.encrypt_secret)
}
