use serde::Deserialize;

use flowy_server::supabase::SupabaseConfiguration;

#[derive(Deserialize, Debug)]
pub struct AppFlowyEnv {
  supabase_config: SupabaseConfiguration,
}

impl AppFlowyEnv {
  pub fn parser(env_str: &str) {
    if let Ok(env) = serde_json::from_str::<AppFlowyEnv>(env_str) {
      tracing::trace!("{:?}", env);
      env.supabase_config.write_env();
    }
  }
}
