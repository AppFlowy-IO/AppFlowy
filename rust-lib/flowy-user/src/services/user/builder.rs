use crate::services::user::{UserSession, UserSessionConfig};
use flowy_net::config::ServerConfig;
use std::sync::Arc;

pub struct UserSessionBuilder {
    config: Option<UserSessionConfig>,
}

impl UserSessionBuilder {
    pub fn new() -> Self { Self { config: None } }

    pub fn root_dir(mut self, dir: &str, server_config: &ServerConfig) -> Self {
        self.config = Some(UserSessionConfig::new(dir, server_config));
        self
    }

    pub fn build(mut self) -> UserSession {
        let config = self.config.take().unwrap();
        UserSession::new(config)
    }
}
