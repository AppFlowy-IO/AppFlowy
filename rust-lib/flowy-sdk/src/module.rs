use flowy_dispatch::prelude::Module;

use crate::deps_resolve::{EditorUserImpl, WorkspaceDatabaseImpl, WorkspaceUserImpl};
use flowy_document::module::FlowyDocument;
use flowy_user::services::user::UserSessionBuilder;
use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig) -> Vec<Module> {
    let user_session = Arc::new(UserSessionBuilder::new().root_dir(&config.root).build());

    let workspace_user_impl = Arc::new(WorkspaceUserImpl {
        user_session: user_session.clone(),
    });

    let workspace_db = Arc::new(WorkspaceDatabaseImpl {
        user_session: user_session.clone(),
    });

    let editor_user = Arc::new(EditorUserImpl {
        user_session: user_session.clone(),
    });

    let document = Arc::new(FlowyDocument::new(editor_user));

    vec![
        flowy_user::module::create(user_session),
        flowy_workspace::module::create(workspace_user_impl, workspace_db, document),
    ]
}
