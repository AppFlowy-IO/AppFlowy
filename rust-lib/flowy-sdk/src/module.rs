use crate::deps_resolve::DocumentDepsResolver;
use flowy_dispatch::prelude::Module;
use flowy_document::module::FlowyDocument;
use flowy_net::config::ServerConfig;
use flowy_user::services::user::UserSession;
use flowy_workspace::prelude::WorkspaceController;
use std::sync::Arc;

pub fn mk_modules(workspace_controller: Arc<WorkspaceController>, user_session: Arc<UserSession>) -> Vec<Module> {
    vec![mk_user_module(user_session), mk_workspace_module(workspace_controller)]
}

fn mk_user_module(user_session: Arc<UserSession>) -> Module { flowy_user::module::create(user_session.clone()) }

fn mk_workspace_module(workspace_controller: Arc<WorkspaceController>) -> Module {
    flowy_workspace::module::create(workspace_controller)
}

pub fn mk_document_module(user_session: Arc<UserSession>, server_config: &ServerConfig) -> Arc<FlowyDocument> {
    let document_deps = DocumentDepsResolver::new(user_session.clone());
    let (user, ws_manager) = document_deps.split_into();
    let document = Arc::new(FlowyDocument::new(user, ws_manager, server_config));
    document
}
