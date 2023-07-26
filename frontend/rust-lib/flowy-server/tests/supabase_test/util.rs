use crate::setup_log;
use flowy_server_config::supabase_config::SupabaseConfiguration;

pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  dotenv::from_filename("./.env.test").ok()?;
  setup_log();
  SupabaseConfiguration::from_env().ok()
}
