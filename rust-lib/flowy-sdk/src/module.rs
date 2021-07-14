use flowy_database::{DBConnection, UserDatabaseConnection};
use flowy_dispatch::prelude::Module;
use flowy_user::prelude::*;
use flowy_workspace::prelude::*;
use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig) -> Vec<Module> {
    let user_session = Arc::new(UserSessionBuilder::new().root_dir(&config.root).build());
    let controller = Arc::new(WorkspaceController::new(user_session.clone()));

    vec![
        flowy_user::module::create(user_session),
        flowy_workspace::module::create(controller),
    ]
}
