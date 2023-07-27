use std::ops::Deref;
use std::sync::Arc;

use postgrest::Postgrest;

use flowy_server_config::supabase_config::SupabaseConfiguration;

/// Creates a wrapper for Postgrest, which allows us to extend the functionality of Postgrest.
pub struct PostgresWrapper(Postgrest);

impl Deref for PostgresWrapper {
  type Target = Postgrest;

  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

pub struct RESTfulPostgresServer {
  pub postgrest: Arc<PostgresWrapper>,
}

impl RESTfulPostgresServer {
  pub fn new(config: SupabaseConfiguration) -> Self {
    let url = format!("{}/rest/v1", config.url);
    let auth = format!("Bearer {}", config.key);
    let postgrest = Postgrest::new(url)
      .insert_header("apikey", config.key)
      .insert_header("Authorization", auth);
    Self {
      postgrest: Arc::new(PostgresWrapper(postgrest)),
    }
  }
}
