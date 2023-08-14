use std::sync::Arc;

use flowy_encrypt::generate_encrypt_secret;
use flowy_error::FlowyResult;
use flowy_sqlite::kv::StorePreferences;
use flowy_user_deps::cloud::UserCloudConfig;

const CLOUD_CONFIG_KEY: &str = "af_user_cloud_config";

fn generate_cloud_config(store_preference: &Arc<StorePreferences>) -> UserCloudConfig {
  let config = UserCloudConfig {
    enable_sync: true,
    enable_encrypt: false,
    encrypt_secret: generate_encrypt_secret(),
  };
  let key = cache_key_for_user();
  store_preference.set_object(&key, config.clone()).unwrap();
  config
}

pub fn save_cloud_config(
  store_preference: &Arc<StorePreferences>,
  config: UserCloudConfig,
) -> FlowyResult<()> {
  let key = cache_key_for_user();
  store_preference.set_object(&key, config)?;
  Ok(())
}

fn cache_key_for_user() -> String {
  CLOUD_CONFIG_KEY.to_string()
}

pub fn get_cloud_config(store_preference: &Arc<StorePreferences>) -> UserCloudConfig {
  let key = cache_key_for_user();
  store_preference
    .get_object::<UserCloudConfig>(&key)
    .unwrap_or_else(|| generate_cloud_config(store_preference))
}
