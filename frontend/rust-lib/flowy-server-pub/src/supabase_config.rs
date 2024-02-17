use serde::{Deserialize, Serialize};

use flowy_error::{ErrorCode, FlowyError};

pub const SUPABASE_URL: &str = "APPFLOWY_CLOUD_ENV_SUPABASE_URL";
pub const SUPABASE_ANON_KEY: &str = "APPFLOWY_CLOUD_ENV_SUPABASE_ANON_KEY";

/// The configuration for the postgres database. It supports deserializing from the json string that
/// passed from the frontend application. [AppFlowyEnv::parser]
#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct SupabaseConfiguration {
  /// The url of the supabase server.
  pub url: String,
  /// The key of the supabase server.
  pub anon_key: String,
}

impl SupabaseConfiguration {
  pub fn from_env() -> Result<Self, FlowyError> {
    let url = std::env::var(SUPABASE_URL)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_URL"))?;

    let anon_key = std::env::var(SUPABASE_ANON_KEY)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing SUPABASE_ANON_KEY"))?;

    if url.is_empty() || anon_key.is_empty() {
      return Err(FlowyError::new(
        ErrorCode::InvalidAuthConfig,
        "Missing SUPABASE_URL or SUPABASE_ANON_KEY",
      ));
    }

    Ok(Self { url, anon_key })
  }

  /// Write the configuration to the environment variables.
  pub fn write_env(&self) {
    std::env::set_var(SUPABASE_URL, &self.url);
    std::env::set_var(SUPABASE_ANON_KEY, &self.anon_key);
  }
}
