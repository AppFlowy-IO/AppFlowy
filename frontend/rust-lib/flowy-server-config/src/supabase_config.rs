use serde::{Deserialize, Serialize};

use flowy_error::{ErrorCode, FlowyError};

pub const ENABLE_SUPABASE_SYNC: &str = "ENABLE_SUPABASE_SYNC";
pub const SUPABASE_URL: &str = "SUPABASE_URL";
pub const SUPABASE_ANON_KEY: &str = "SUPABASE_ANON_KEY";
pub const SUPABASE_KEY: &str = "SUPABASE_KEY";
pub const SUPABASE_JWT_SECRET: &str = "SUPABASE_JWT_SECRET";

pub const SUPABASE_DB: &str = "SUPABASE_DB";
pub const SUPABASE_DB_USER: &str = "SUPABASE_DB_USER";
pub const SUPABASE_DB_PASSWORD: &str = "SUPABASE_DB_PASSWORD";
pub const SUPABASE_DB_PORT: &str = "SUPABASE_DB_PORT";

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct SupabaseConfiguration {
  /// The url of the supabase server.
  pub url: String,

  /// The key of the supabase server.
  pub key: String,
  /// The secret used to sign the JWT tokens.
  pub jwt_secret: String,

  pub enable_sync: bool,

  pub postgres_config: PostgresConfiguration,
}

impl SupabaseConfiguration {
  /// Load the configuration from the environment variables.
  /// SUPABASE_URL=https://<your-supabase-url>.supabase.co
  /// SUPABASE_KEY=<your-supabase-key>
  /// SUPABASE_JWT_SECRET=<your-supabase-jwt-secret>
  ///
  pub fn from_env() -> Result<Self, FlowyError> {
    let postgres_config = PostgresConfiguration::from_env()?;
    Ok(Self {
      enable_sync: std::env::var(ENABLE_SUPABASE_SYNC)
        .map(|v| v == "true")
        .unwrap_or(false),
      url: std::env::var(SUPABASE_URL)
        .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_URL"))?,
      key: std::env::var(SUPABASE_KEY)
        .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_KEY"))?,
      jwt_secret: std::env::var(SUPABASE_JWT_SECRET).map_err(|_| {
        FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_JWT_SECRET")
      })?,
      postgres_config,
    })
  }

  pub fn write_env(&self) {
    if self.enable_sync {
      std::env::set_var(ENABLE_SUPABASE_SYNC, "true");
    } else {
      std::env::set_var(ENABLE_SUPABASE_SYNC, "false");
    }
    std::env::set_var(SUPABASE_URL, &self.url);
    std::env::set_var(SUPABASE_KEY, &self.key);
    std::env::set_var(SUPABASE_JWT_SECRET, &self.jwt_secret);
    self.postgres_config.write_env();
  }
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct PostgresConfiguration {
  pub url: String,
  pub user_name: String,
  pub password: String,
  pub port: u16,
}

impl PostgresConfiguration {
  pub fn from_env() -> Result<Self, FlowyError> {
    let url = std::env::var(SUPABASE_DB)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_DB"))?;
    let user_name = std::env::var(SUPABASE_DB_USER)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_DB_USER"))?;
    let password = std::env::var(SUPABASE_DB_PASSWORD)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_DB_PASSWORD"))?;
    let port = std::env::var(SUPABASE_DB_PORT)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_DB_PORT"))?
      .parse::<u16>()
      .map_err(|_e| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_DB_PORT"))?;

    Ok(Self {
      url,
      user_name,
      password,
      port,
    })
  }

  pub fn write_env(&self) {
    std::env::set_var(SUPABASE_DB, &self.url);
    std::env::set_var(SUPABASE_DB_USER, &self.user_name);
    std::env::set_var(SUPABASE_DB_PASSWORD, &self.password);
    std::env::set_var(SUPABASE_DB_PORT, self.port.to_string());
  }
}
