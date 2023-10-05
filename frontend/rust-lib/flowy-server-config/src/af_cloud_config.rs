use serde::{Deserialize, Serialize};

use flowy_error::{ErrorCode, FlowyError};

pub const APPFLOWY_CLOUD_BASE_URL: &str = "APPFLOWY_CLOUD_BASE_URL";
pub const APPFLOWY_CLOUD_WS_BASE_URL: &str = "APPFLOWY_CLOUD_WS_BASE_URL";
pub const APPFLOWY_CLOUD_GOTRUE_URL: &str = "APPFLOWY_CLOUD_GOTRUE_URL";

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct AFCloudConfiguration {
  pub base_url: String,
  pub ws_base_url: String,
  pub gotrue_url: String,
}

impl AFCloudConfiguration {
  pub fn from_env() -> Result<Self, FlowyError> {
    let base_url = std::env::var(APPFLOWY_CLOUD_BASE_URL).map_err(|_| {
      FlowyError::new(
        ErrorCode::InvalidAuthConfig,
        "Missing APPFLOWY_CLOUD_BASE_URL",
      )
    })?;

    let ws_base_url = std::env::var(APPFLOWY_CLOUD_WS_BASE_URL).map_err(|_| {
      FlowyError::new(
        ErrorCode::InvalidAuthConfig,
        "Missing APPFLOWY_CLOUD_WS_BASE_URL",
      )
    })?;

    let gotrue_url = std::env::var(APPFLOWY_CLOUD_GOTRUE_URL)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing AF_CLOUD_GOTRUE_URL"))?;

    Ok(Self {
      base_url,
      ws_base_url,
      gotrue_url,
    })
  }

  /// Write the configuration to the environment variables.
  pub fn write_env(&self) {
    std::env::set_var(APPFLOWY_CLOUD_BASE_URL, &self.base_url);
    std::env::set_var(APPFLOWY_CLOUD_WS_BASE_URL, &self.ws_base_url);
    std::env::set_var(APPFLOWY_CLOUD_GOTRUE_URL, &self.gotrue_url);
  }
}
