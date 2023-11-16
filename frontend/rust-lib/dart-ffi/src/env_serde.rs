use serde::Deserialize;

use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_server_config::supabase_config::SupabaseConfiguration;

#[derive(Deserialize, Debug)]
pub struct AppFlowyEnv {
  supabase_config: SupabaseConfiguration,
  appflowy_cloud_config: AFCloudConfiguration,
}

impl AppFlowyEnv {
  /// Parse the environment variable from the frontend application. The frontend will
  /// pass the environment variable as a json string after launching.
  pub fn write_env_from(env_str: &str) {
    if let Ok(env) = serde_json::from_str::<AppFlowyEnv>(env_str) {
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
