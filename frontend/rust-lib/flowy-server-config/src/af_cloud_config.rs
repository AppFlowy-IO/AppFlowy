use serde::{Deserialize, Serialize};

use flowy_error::{ErrorCode, FlowyError};

pub const AF_CLOUD_BASE_URL: &str = "AF_CLOUD_BASE_URL";
pub const AF_CLOUD_WS_BASE_URL: &str = "AF_CLOUD_WS_BASE_URL";
pub const AF_CLOUD_GOTRUE_URL: &str = "AF_GOTRUE_URL";

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct AFCloudConfiguration {
  pub base_url: String,
  pub base_ws_url: String,
  pub gotrue_url: String,
}

impl AFCloudConfiguration {
  pub fn from_env() -> Result<Self, FlowyError> {
    let base_url = std::env::var(AF_CLOUD_BASE_URL)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing AF_CLOUD_BASE_URL"))?;

    let base_ws_url = std::env::var(AF_CLOUD_WS_BASE_URL)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing AF_CLOUD_WS_BASE_URL"))?;

    let gotrue_url = std::env::var(AF_CLOUD_GOTRUE_URL)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidAuthConfig, "Missing AF_CLOUD_GOTRUE_URL"))?;

    Ok(Self {
      base_url,
      base_ws_url,
      gotrue_url,
    })
  }

  /// Write the configuration to the environment variables.
  pub fn write_env(&self) {
    std::env::set_var(AF_CLOUD_BASE_URL, &self.base_url);
    std::env::set_var(AF_CLOUD_WS_BASE_URL, &self.base_ws_url);
    std::env::set_var(AF_CLOUD_GOTRUE_URL, &self.gotrue_url);
  }
}
