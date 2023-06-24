use std::sync::mpsc::Receiver;
use std::sync::Arc;

use serde::Deserialize;
use tokio::sync::Mutex;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder2::deps::FolderCloudService;
use flowy_user::event_map::UserAuthService;

use crate::supabase::impls::PostgrestUserAuthServiceImpl;
use crate::supabase::pg_db::{PostgresClient, PostgresDB};
use crate::AppFlowyServer;

pub const SUPABASE_URL: &str = "SUPABASE_URL";
pub const SUPABASE_ANON_KEY: &str = "SUPABASE_ANON_KEY";
pub const SUPABASE_KEY: &str = "SUPABASE_KEY";
pub const SUPABASE_JWT_SECRET: &str = "SUPABASE_JWT_SECRET";

#[derive(Debug, Deserialize)]
pub struct SupabaseConfiguration {
  /// The url of the supabase server.
  pub url: String,
  /// The key of the supabase server.
  pub key: String,
  /// The secret used to sign the JWT tokens.
  pub jwt_secret: String,
}

impl SupabaseConfiguration {
  /// Load the configuration from the environment variables.
  /// SUPABASE_URL=https://<your-supabase-url>.supabase.co
  /// SUPABASE_KEY=<your-supabase-key>
  /// SUPABASE_JWT_SECRET=<your-supabase-jwt-secret>
  ///
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

  pub fn write_env(&self) {
    std::env::set_var(SUPABASE_URL, &self.url);
    std::env::set_var(SUPABASE_KEY, &self.key);
    std::env::set_var(SUPABASE_JWT_SECRET, &self.jwt_secret);
  }
}

pub struct SupabaseServer {
  pub postgres: Arc<PostgresServer>,
}

impl SupabaseServer {
  pub fn new() -> Self {
    Self {
      postgres: Arc::new(PostgresServer::new()),
    }
  }
}

pub struct PostgresServer(Arc<Mutex<Option<Arc<PostgresDB>>>>);

impl PostgresServer {
  pub fn new() -> Self {
    Self(Arc::new(Mutex::new(None)))
  }

  pub async fn pg_client(&self) -> Result<Arc<PostgresClient>, FlowyError> {
    let mut postgres = self.0.lock().await;
    match &*postgres {
      None => match PostgresDB::from_env().await {
        Ok(db) => {
          let db = Arc::new(db);
          *postgres = Some(db.clone());
          Ok(db.client.clone())
        },
        Err(e) => Err(FlowyError::new(
          ErrorCode::PostgresDatabaseConnectError,
          e.to_string(),
        )),
      },
      Some(postgrest) => Ok(postgrest.client.clone()),
    }
  }
}

impl AppFlowyServer for SupabaseServer {
  fn user_service(&self) -> Arc<dyn UserAuthService> {
    Arc::new(PostgrestUserAuthServiceImpl::new(self.postgres.clone()))
  }

  fn folder_service(&self) -> Arc<dyn FolderCloudService> {
    todo!()
  }
}

struct SupabaseServerRunner(Receiver<()>);
