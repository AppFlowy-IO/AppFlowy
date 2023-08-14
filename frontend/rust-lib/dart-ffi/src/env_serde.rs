use serde::Deserialize;

use flowy_server_config::supabase_config::SupabaseConfiguration;

#[derive(Deserialize, Debug)]
pub struct AppFlowyEnv {
  supabase_config: SupabaseConfiguration,
}

impl AppFlowyEnv {
  /// Parse the environment variable from the frontend application. The frontend will
  /// pass the environment variable as a json string after launching.
  pub fn parser(env_str: &str) {
    if let Ok(env) = serde_json::from_str::<AppFlowyEnv>(env_str) {
      env.supabase_config.write_env();
    }
  }
}
