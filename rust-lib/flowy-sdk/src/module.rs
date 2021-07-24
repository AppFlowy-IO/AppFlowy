use crate::flowy_server::{ArcFlowyServer, FlowyServerMocker};
use flowy_dispatch::prelude::Module;
use flowy_editor::prelude::*;
use flowy_user::prelude::*;

use crate::deps_resolve::{
    EditorDatabaseImpl,
    EditorUserImpl,
    WorkspaceDatabaseImpl,
    WorkspaceUserImpl,
};
use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig, _server: ArcFlowyServer) -> Vec<Module> {
    let user_session = Arc::new(
        UserSessionBuilder::new()
            .root_dir(&config.root)
            .build(Arc::new(FlowyServerMocker {})),
    );

    let workspace_user_impl = Arc::new(WorkspaceUserImpl {
        user_session: user_session.clone(),
    });

    let workspace_db = Arc::new(WorkspaceDatabaseImpl {
        user_session: user_session.clone(),
    });

    let editor_db = Arc::new(EditorDatabaseImpl {
        user_session: user_session.clone(),
    });
    let editor_user = Arc::new(EditorUserImpl {
        user_session: user_session.clone(),
    });

    vec![
        flowy_user::module::create(user_session),
        flowy_workspace::module::create(workspace_user_impl, workspace_db),
        flowy_editor::module::create(editor_db, editor_user),
    ]
}
