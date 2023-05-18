use std::sync::Arc;

use postgrest::Postgrest;

use flowy_user::event_map::UserAuthService;

use crate::supabase::user::PostgrestUserAuthServiceImpl;
use crate::AppFlowyServer;

pub struct SupabaseServerConfiguration {
  pub supabase_url: String,
  pub supabase_key: String,
  pub supabase_jwt: String,
}

pub struct SupabaseServer {
  postgres: Arc<Postgrest>,
}

impl SupabaseServer {
  pub fn new(config: SupabaseServerConfiguration) -> Self {
    let postgres = Arc::new(Postgrest::new(config.supabase_url));
    Self { postgres }
  }
}

impl AppFlowyServer for SupabaseServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(PostgrestUserAuthServiceImpl::new(self.postgres.clone()))
  }
}
