use crate::services::{
    user::{UserSession, UserSessionConfig},
    workspace::WorkspaceAction,
};
use std::sync::Arc;

pub struct UserSessionBuilder {
    config: Option<UserSessionConfig>,
}

impl UserSessionBuilder {
    pub fn new() -> Self { Self { config: None } }

    pub fn root_dir(mut self, dir: &str) -> Self {
        self.config = Some(UserSessionConfig::new(dir));
        self
    }

    pub fn build<S>(mut self, workspace: Arc<S>) -> UserSession
    where
        S: 'static + WorkspaceAction + Send + Sync,
    {
        let config = self.config.take().unwrap();

        UserSession::new(config, workspace)
    }
}
