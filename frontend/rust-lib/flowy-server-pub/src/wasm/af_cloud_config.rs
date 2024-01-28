use serde::{Deserialize, Serialize};
use std::fmt::Display;

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct AFCloudConfiguration {
  pub base_url: String,
  pub ws_base_url: String,
  pub gotrue_url: String,
}

impl Display for AFCloudConfiguration {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    f.write_fmt(format_args!(
      "base_url: {}, ws_base_url: {}, gotrue_url: {}",
      self.base_url, self.ws_base_url, self.gotrue_url,
    ))
  }
}
