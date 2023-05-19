use std::sync::Arc;

use postgrest::Postgrest;

use flowy_config::entities::{SUPABASE_JWT_SECRET, SUPABASE_KEY, SUPABASE_URL};
use flowy_error::{ErrorCode, FlowyError};
use flowy_user::event_map::UserAuthService;

use crate::supabase::user::PostgrestUserAuthServiceImpl;
use crate::AppFlowyServer;

pub struct SupabaseConfiguration {
  /// The url of the supabase server.
  pub url: String,
  /// The key of the supabase server.
  pub key: String,
  /// The secret used to sign the JWT tokens.
  pub jwt_secret: String,
}

impl SupabaseConfiguration {
  pub fn from_env() -> Result<Self, FlowyError> {
    Ok(Self {
      url: std::env::var(SUPABASE_URL)
        .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_URL"))?,
      key: std::env::var(SUPABASE_KEY)
        .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_KEY"))?,
      jwt_secret: std::env::var(SUPABASE_JWT_SECRET).map_err(|_| {
        FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_JWT_SECRET")
      })?,
    })
  }
}

pub struct SupabaseServer {
  pub postgres: Arc<Postgrest>,
}

impl SupabaseServer {
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

impl AppFlowyServer for SupabaseServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(PostgrestUserAuthServiceImpl::new(self.postgres.clone()))
  }
}
