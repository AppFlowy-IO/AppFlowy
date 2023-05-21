use std::convert::{TryFrom, TryInto};

use config::FileFormat;
use serde_aux::field_attributes::deserialize_number_from_string;

pub const HEADER_TOKEN: &str = "token";

#[derive(serde::Deserialize, Clone, Debug)]
pub struct SelfHostedConfiguration {
  #[serde(deserialize_with = "deserialize_number_from_string")]
  pub port: u16,
  pub host: String,
  pub http_scheme: String,
  pub ws_scheme: String,
}

pub fn self_host_server_configuration() -> Result<SelfHostedConfiguration, config::ConfigError> {
  let mut settings = config::Config::default();
  let base = include_str!("./configuration/base.yaml");
  settings.merge(config::File::from_str(base, FileFormat::Yaml).required(true))?;

  let environment: Environment = std::env::var("APP_ENVIRONMENT")
    .unwrap_or_else(|_| "local".into())
    .try_into()
    .expect("Failed to parse APP_ENVIRONMENT.");

  let custom = match environment {
    Environment::Local => include_str!("./configuration/local.yaml"),
    Environment::Production => include_str!("./configuration/production.yaml"),
  };

  settings.merge(config::File::from_str(custom, FileFormat::Yaml).required(true))?;
  settings.try_into()
}

impl SelfHostedConfiguration {
  pub fn reset_host_with_port(&mut self, host: &str, port: u16) {
    self.host = host.to_owned();
    self.port = port;
  }

  pub fn base_url(&self) -> String {
    format!("{}://{}:{}", self.http_scheme, self.host, self.port)
  }

  pub fn sign_up_url(&self) -> String {
    format!("{}/api/register", self.base_url())
  }

  pub fn sign_in_url(&self) -> String {
    format!("{}/api/auth", self.base_url())
  }

  pub fn sign_out_url(&self) -> String {
    format!("{}/api/auth", self.base_url())
  }

  pub fn user_profile_url(&self) -> String {
    format!("{}/api/user", self.base_url())
  }

  pub fn workspace_url(&self) -> String {
    format!("{}/api/workspace", self.base_url())
  }

  pub fn app_url(&self) -> String {
    format!("{}/api/app", self.base_url())
  }

  pub fn view_url(&self) -> String {
    format!("{}/api/view", self.base_url())
  }

  pub fn doc_url(&self) -> String {
    format!("{}/api/doc", self.base_url())
  }

  pub fn trash_url(&self) -> String {
    format!("{}/api/trash", self.base_url())
  }

  pub fn ws_addr(&self) -> String {
    format!("{}://{}:{}/ws", self.ws_scheme, self.host, self.port)
  }
}

pub enum Environment {
  Local,
  Production,
}

impl Environment {
  #[allow(dead_code)]
  pub fn as_str(&self) -> &'static str {
    match self {
      Environment::Local => "local",
      Environment::Production => "production",
    }
  }
}

impl TryFrom<String> for Environment {
  type Error = String;

  fn try_from(s: String) -> Result<Self, Self::Error> {
    match s.to_lowercase().as_str() {
      "local" => Ok(Self::Local),
      "production" => Ok(Self::Production),
      other => Err(format!(
        "{} is not a supported environment. Use either `local` or `production`.",
        other
      )),
    }
  }
}
