use flowy_dispatch::prelude::Module;
use flowy_user::prelude::UserSessionBuilder;
use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig) -> Vec<Module> {
    let user_session = UserSessionBuilder::new().root_dir(&config.root).build();
    vec![flowy_user::module::create(Arc::new(user_session))]
}
