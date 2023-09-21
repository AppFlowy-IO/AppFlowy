use std::sync::Arc;

use parking_lot::RwLock;

use flowy_server::af_cloud::AFCloudServer;
use flowy_server_config::af_cloud_config::AFCloudConfiguration;

use crate::setup_log;

#[allow(dead_code)]
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
