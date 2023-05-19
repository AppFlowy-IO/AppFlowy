use std::sync::Arc;

use postgrest::Postgrest;

use flowy_config::entities::{SUPABASE_JWT_SECRET, SUPABASE_KEY, SUPABASE_URL};
use flowy_error::{ErrorCode, FlowyError};
use flowy_user::event_map::UserAuthService;

use crate::supabase::user::PostgrestUserAuthServiceImpl;
use crate::AppFlowyServer;

pub struct SupabaseServerConfiguration {
  pub supabase_url: String,
  pub supabase_key: String,
  pub supabase_jwt_secret: String,
}

impl SupabaseServerConfiguration {
  pub fn from_env() -> Result<Self, FlowyError> {
    Ok(Self {
      supabase_url: std::env::var(SUPABASE_URL)
        .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_URL"))?,
      supabase_key: std::env::var(SUPABASE_KEY)
        .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_KEY"))?,
      supabase_jwt_secret: std::env::var(SUPABASE_JWT_SECRET).map_err(|_| {
        FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_JWT_SECRET")
      })?,
    })
  }
}

pub struct SupabaseServer {
  pub postgres: Arc<Postgrest>,
}

impl SupabaseServer {
  pub fn new(config: SupabaseServerConfiguration) -> Self {
    let url = format!("{}/rest/v1/", config.supabase_url);
    let auth = format!("Bearer {}", config.supabase_key);
    let postgrest = Postgrest::new(url)
      .insert_header("apikey", config.supabase_key)
      .insert_header("Authorization", auth);
    let postgres = Arc::new(postgrest);
    Self { postgres }
  }
}

impl AppFlowyServer for SupabaseServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(PostgrestUserAuthServiceImpl::new(self.postgres.clone()))
  }
}
