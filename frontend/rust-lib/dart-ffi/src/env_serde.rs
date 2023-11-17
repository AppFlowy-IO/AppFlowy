use serde::Deserialize;
use serde_repr::Deserialize_repr;

use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_server_config::supabase_config::SupabaseConfiguration;

#[derive(Deserialize, Debug)]
pub struct AppFlowyEnv {
  cloud_type: CloudType,
  supabase_config: SupabaseConfiguration,
  appflowy_cloud_config: AFCloudConfiguration,
}

const CLOUT_TYPE_STR: &str = "APPFLOWY_CLOUD_ENV_CLOUD_TYPE";

#[derive(Deserialize_repr, Debug, Clone)]
#[repr(u8)]
pub enum CloudType {
  Local = 0,
  Supabase = 1,
  AppFlowyCloud = 2,
}

impl CloudType {
  fn write_env(&self) {
    let s = self.clone() as u8;
    std::env::set_var(CLOUT_TYPE_STR, s.to_string());
  }

  #[allow(dead_code)]
  fn from_str(s: &str) -> Self {
    match s {
      "0" => CloudType::Local,
      "1" => CloudType::Supabase,
      "2" => CloudType::AppFlowyCloud,
      _ => CloudType::Local,
    }
  }

  #[allow(dead_code)]
  pub fn from_env() -> Self {
    let cloud_type_str = std::env::var(CLOUT_TYPE_STR).unwrap_or_default();
    CloudType::from_str(&cloud_type_str)
  }
}

impl AppFlowyEnv {
  /// Parse the environment variable from the frontend application. The frontend will
  /// pass the environment variable as a json string after launching.
  pub fn write_env_from(env_str: &str) {
    if let Ok(env) = serde_json::from_str::<AppFlowyEnv>(env_str) {
      let _ = env.cloud_type.write_env();
      let is_valid = env.appflowy_cloud_config.write_env().is_ok();
      // Note on Configuration Priority:
      // If both Supabase config and AppFlowy cloud config are provided in the '.env' file,
      // the AppFlowy cloud config will be prioritized and the Supabase config ignored.
      // Ensure only one of these configurations is active at any given time.
      if !is_valid {
        let _ = env.supabase_config.write_env();
      }
    }
  }
}
