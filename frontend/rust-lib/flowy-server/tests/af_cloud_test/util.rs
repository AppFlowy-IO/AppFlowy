use client_api::ClientConfiguration;
use semver::Version;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

use flowy_error::{FlowyError, FlowyResult};
use uuid::Uuid;

use crate::setup_log;
use flowy_server::af_cloud::define::LoginUserService;
use flowy_server::af_cloud::AppFlowyCloudServer;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_sqlite::DBConnection;
use lib_infra::async_trait::async_trait;

/// To run the test, create a .env.ci file in the 'flowy-server' directory and set the following environment variables:
///
/// - `APPFLOWY_CLOUD_BASE_URL=http://localhost:8000`
/// - `APPFLOWY_CLOUD_WS_BASE_URL=ws://localhost:8000/ws`
/// - `APPFLOWY_CLOUD_GOTRUE_URL=http://localhost:9998`
///
/// - `GOTRUE_ADMIN_EMAIL=admin@example.com`
/// - `GOTRUE_ADMIN_PASSWORD=password`
pub fn get_af_cloud_config() -> Option<AFCloudConfiguration> {
  dotenv::from_filename("./.env.ci").ok()?;
  setup_log();
  AFCloudConfiguration::from_env().ok()
}

pub fn af_cloud_server(config: AFCloudConfiguration) -> Arc<AppFlowyCloudServer> {
  let fake_device_id = uuid::Uuid::new_v4().to_string();
  Arc::new(AppFlowyCloudServer::new(
    config,
    true,
    fake_device_id,
    Version::new(0, 5, 8),
    Arc::new(FakeServerUserImpl),
  ))
}

struct FakeServerUserImpl;

#[async_trait]
impl LoginUserService for FakeServerUserImpl {
  fn workspace_id(&self) -> FlowyResult<Uuid> {
    todo!()
  }

  fn user_id(&self) -> FlowyResult<i64> {
    todo!()
  }

  async fn is_local_mode(&self) -> FlowyResult<bool> {
    Ok(true)
  }

  fn get_sqlite_db(&self, _uid: i64) -> Result<DBConnection, FlowyError> {
    todo!()
  }

  fn application_root_dir(&self) -> Result<PathBuf, FlowyError> {
    todo!()
  }
}

pub async fn generate_sign_in_url(user_email: &str, config: &AFCloudConfiguration) -> String {
  let client = client_api::Client::new(
    &config.base_url,
    &config.ws_base_url,
    &config.gotrue_url,
    "fake_device_id",
    ClientConfiguration::default(),
    "test",
  );
  let admin_email = std::env::var("GOTRUE_ADMIN_EMAIL").unwrap();
  let admin_password = std::env::var("GOTRUE_ADMIN_PASSWORD").unwrap();
  let admin_client = client_api::Client::new(
    client.base_url(),
    client.ws_addr(),
    client.gotrue_url(),
    "fake_device_id",
    ClientConfiguration::default(),
    &client.client_version.to_string(),
  );
  admin_client
    .sign_in_password(&admin_email, &admin_password)
    .await
    .unwrap();

  let action_link = admin_client
    .generate_sign_in_action_link(user_email)
    .await
    .unwrap();
  client.extract_sign_in_url(&action_link).await.unwrap()
}

pub async fn af_cloud_sign_up_param(
  email: &str,
  config: &AFCloudConfiguration,
) -> HashMap<String, String> {
  let mut params = HashMap::new();
  params.insert(
    "sign_in_url".to_string(),
    generate_sign_in_url(email, config).await,
  );
  params.insert("device_id".to_string(), Uuid::new_v4().to_string());
  params
}

pub fn generate_test_email() -> String {
  format!("{}@test.com", Uuid::new_v4())
}
