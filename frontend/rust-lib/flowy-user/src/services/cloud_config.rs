use std::sync::Arc;

use flowy_encrypt::generate_encrypt_secret;
use flowy_error::FlowyResult;
use flowy_sqlite::kv::StorePreferences;
use flowy_user_deps::cloud::UserCloudConfig;

const CLOUD_CONFIG_KEY: &str = "af_user_cloud_config";

pub fn generate_cloud_config(store_preference: &Arc<StorePreferences>) -> UserCloudConfig {
  let config = UserCloudConfig::new(generate_encrypt_secret());
  let key = cache_key_for_cloud_config();
  store_preference.set_object(&key, config.clone()).unwrap();
  config
}

pub fn remove_cloud_config(store_preference: &Arc<StorePreferences>) {
  let key = cache_key_for_cloud_config();
  store_preference.remove(&key);
}

pub fn save_cloud_config(
  store_preference: &Arc<StorePreferences>,
  config: UserCloudConfig,
) -> FlowyResult<()> {
  let key = cache_key_for_cloud_config();
  store_preference.set_object(&key, config)?;
  Ok(())
}

fn cache_key_for_cloud_config() -> String {
  CLOUD_CONFIG_KEY.to_string()
}

pub fn get_cloud_config(store_preference: &Arc<StorePreferences>) -> Option<UserCloudConfig> {
  let key = cache_key_for_cloud_config();
  store_preference.get_object::<UserCloudConfig>(&key)
}

pub fn get_encrypt_secret(store_preference: &Arc<StorePreferences>) -> Option<String> {
  let key = cache_key_for_cloud_config();
  store_preference
    .get_object::<UserCloudConfig>(&key)
    .map(|config| config.encrypt_secret)
}
