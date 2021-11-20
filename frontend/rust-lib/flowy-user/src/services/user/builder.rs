use crate::services::user::{UserSession, UserSessionConfig};
use backend_service::config::ServerConfig;

pub struct UserSessionBuilder {
    config: Option<UserSessionConfig>,
}

impl UserSessionBuilder {
    pub fn new() -> Self { Self { config: None } }

    pub fn root_dir(mut self, dir: &str, server_config: &ServerConfig, session_cache_key: &str) -> Self {
        self.config = Some(UserSessionConfig::new(dir, server_config, session_cache_key));
        self
    }

    pub fn build(mut self) -> UserSession {
        let config = self.config.take().unwrap();
        UserSession::new(config)
    }
}
