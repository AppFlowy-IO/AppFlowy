use crate::services::{
    user::{UserSession, UserSessionConfig},
    workspace::UserWorkspaceController,
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

    pub fn build<S>(mut self, workspace_controller: Arc<S>) -> UserSession
    where
        S: 'static + UserWorkspaceController + Send + Sync,
    {
        let config = self.config.take().unwrap();

        UserSession::new(config, workspace_controller)
    }
}
