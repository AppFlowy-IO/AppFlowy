use std::collections::HashMap;
use std::sync::Arc;

use parking_lot::RwLock;
use uuid::Uuid;

use flowy_server::af_cloud::AFCloudServer;
use flowy_server::supabase::define::{USER_DEVICE_ID, USER_SIGN_IN_URL};
use flowy_server_config::af_cloud_config::AFCloudConfiguration;

use crate::setup_log;

pub fn get_af_cloud_config() -> Option<AFCloudConfiguration> {
  dotenv::from_filename("./.env.ci").ok()?;
  setup_log();
  AFCloudConfiguration::from_env().ok()
}

pub fn af_cloud_server(config: AFCloudConfiguration) -> Arc<AFCloudServer> {
  let fake_device_id = uuid::Uuid::new_v4().to_string();
  let device_id = Arc::new(RwLock::new(fake_device_id));
  Arc::new(AFCloudServer::new(config, true, device_id))
}

pub async fn generate_sign_in_url(user_email: &str, config: &AFCloudConfiguration) -> String {
  let api_client =
    client_api::Client::new(&config.base_url, &config.ws_base_url, &config.gotrue_url);

  let admin_email = std::env::var("GOTRUE_ADMIN_EMAIL").unwrap();
  let admin_password = std::env::var("GOTRUE_ADMIN_PASSWORD").unwrap();
  api_client
    .generate_sign_in_url_with_email(&admin_email, &admin_password, user_email)
    .await
    .unwrap()
}

pub async fn af_cloud_sign_up_param(
  email: &str,
  config: &AFCloudConfiguration,
) -> HashMap<String, String> {
  let mut params = HashMap::new();
  params.insert(
    USER_SIGN_IN_URL.to_string(),
    generate_sign_in_url(email, config).await,
  );
  params.insert(USER_DEVICE_ID.to_string(), Uuid::new_v4().to_string());
  params
}

pub fn generate_test_email() -> String {
  format!("{}@test.com", Uuid::new_v4())
}
