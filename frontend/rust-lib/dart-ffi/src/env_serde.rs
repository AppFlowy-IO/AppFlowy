use std::collections::HashMap;

use serde::Deserialize;

use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_server_pub::supabase_config::SupabaseConfiguration;
use flowy_server_pub::AuthenticatorType;

#[derive(Deserialize, Debug)]
pub struct AppFlowyDartConfiguration {
  /// The root path of the application
  pub root: String,
  pub app_version: String,
  /// This path will be used to store the user data
  pub custom_app_path: String,
  pub origin_app_path: String,
  pub device_id: String,
  pub platform: String,
  pub authenticator_type: AuthenticatorType,
  pub(crate) supabase_config: SupabaseConfiguration,
  pub(crate) appflowy_cloud_config: AFCloudConfiguration,
  #[serde(default)]
  pub(crate) envs: HashMap<String, String>,
}

impl AppFlowyDartConfiguration {
  pub fn from_str(s: &str) -> Self {
    serde_json::from_str::<AppFlowyDartConfiguration>(s).unwrap()
  }

  pub fn write_env(&self) {
    self.authenticator_type.write_env();
    self.appflowy_cloud_config.write_env();
    self.supabase_config.write_env();

    for (k, v) in self.envs.iter() {
      std::env::set_var(k, v);
    }
  }
}
