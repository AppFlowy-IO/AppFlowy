use appflowy_integrate::SupabaseDBConfig;
use flowy_server::supabase::SupabaseConfiguration;
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct AppFlowyEnv {
  supabase_config: SupabaseConfiguration,
  supabase_db_config: SupabaseDBConfig,
}

impl AppFlowyEnv {
  pub fn parser(env_str: &str) {
    if let Ok(env) = serde_json::from_str::<AppFlowyEnv>(env_str) {
      tracing::trace!("{:?}", env);
      env.supabase_config.write_env();
      env.supabase_db_config.write_env();
    }
  }
}
