use std::sync::Arc;

use postgrest::Postgrest;

use flowy_server_config::supabase_config::SupabaseConfiguration;

pub struct SLPostgresServer {
  pub postgres: Arc<Postgrest>,
}

impl SLPostgresServer {
  pub fn new(config: SupabaseConfiguration) -> Self {
    let url = format!("{}/rest/v1/", config.url);
    let auth = format!("Bearer {}", config.key);
    let postgrest = Postgrest::new(url)
      .insert_header("apikey", config.key)
      .insert_header("Authorization", auth);
    let postgres = Arc::new(postgrest);
    Self { postgres }
  }
}
