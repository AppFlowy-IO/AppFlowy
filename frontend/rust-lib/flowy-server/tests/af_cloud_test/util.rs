use flowy_server_config::af_cloud_config::AFCloudConfiguration;

use crate::setup_log;

pub fn get_af_cloud_config() -> Option<AFCloudConfiguration> {
  dotenv::from_filename("./.env.ci").ok()?;
  setup_log();
  AFCloudConfiguration::from_env().ok()
}
