use std::convert::{TryFrom, TryInto};

use config::FileFormat;
use serde_aux::field_attributes::deserialize_number_from_string;

pub const HEADER_TOKEN: &str = "token";

#[derive(serde::Deserialize, Clone, Debug)]
pub struct AFCloudConfiguration {
  #[serde(deserialize_with = "deserialize_number_from_string")]
  pub port: u16,
  pub host: String,
  pub http_scheme: String,
  pub ws_scheme: String,
}

pub fn appflowy_cloud_server_configuration() -> Result<AFCloudConfiguration, config::ConfigError> {
  let mut settings = config::Config::default();
  let base = include_str!("./configuration/base.yaml");
  settings.merge(config::File::from_str(base, FileFormat::Yaml).required(true))?;

  let environment: Environment = std::env::var("APP_ENVIRONMENT")
    .unwrap_or_else(|_| "local".to_owned())
    .try_into()
    .expect("Failed to parse APP_ENVIRONMENT.");

  let custom = match environment {
    Environment::Local => include_str!("./configuration/local.yaml"),
    Environment::Production => include_str!("./configuration/production.yaml"),
  };

  settings.merge(config::File::from_str(custom, FileFormat::Yaml).required(true))?;
  settings.try_into()
}

impl AFCloudConfiguration {
  pub fn reset_host_with_port(&mut self, host: &str, port: u16) {
    self.host = host.to_owned();
    self.port = port;
  }

  pub fn base_url(&self) -> String {
    format!("{}://{}:{}", self.http_scheme, self.host, self.port)
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
