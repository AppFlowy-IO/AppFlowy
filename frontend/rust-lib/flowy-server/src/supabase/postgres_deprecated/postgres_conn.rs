use std::sync::Arc;

use postgrest::Postgrest;

use crate::supabase::SupabaseConfiguration;

pub struct PostgresHttp {
  pub postgres: Arc<Postgrest>,
}

impl PostgresHttp {
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
