use flowy_dispatch::prelude::Module;
use flowy_user::prelude::user_session::{UserSession, UserSessionConfig};
use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig) -> Vec<Module> {
    let user_config = UserSessionConfig::new(&config.root);
    let user_session = Arc::new(UserSession::new(user_config));

    vec![flowy_user::module::create(user_session)]
}
