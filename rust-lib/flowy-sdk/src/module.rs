use flowy_dispatch::prelude::Module;

use crate::deps_resolve::{EditorUserImpl, WorkspaceDatabaseImpl, WorkspaceUserImpl};
use flowy_document::module::FlowyDocument;
use flowy_user::services::user::UserSessionBuilder;
use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig) -> Vec<Module> {
    // runtime.spawn(async move {
    // start_ws_connection("eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.
    // eyJpc3MiOiJsb2NhbGhvc3QiLCJzdWIiOiJhdXRoIiwiaWF0IjoxNjMxNzcwODQ2LCJleHAiOjE2MzIyMDI4NDYsInVzZXJfaWQiOiI5ZmFiN2I4MS1mZDAyLTRhN2EtYjA4Zi05NDM3NTdmZmE5MDcifQ.
    // UzV01tHnWEZWBp3nJPTmFi7ypxBoCe56AjEPb9bnsFE") });
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
