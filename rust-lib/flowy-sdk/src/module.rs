use crate::deps_resolve::{DocumentDepsResolver, WorkspaceDepsResolver};
use flowy_dispatch::prelude::Module;
use flowy_document::module::FlowyDocument;
use flowy_net::config::ServerConfig;
use flowy_user::services::user::UserSession;
use std::sync::Arc;

pub fn build_modules(
    server_config: &ServerConfig,
    user_session: Arc<UserSession>,
    flowy_document: Arc<FlowyDocument>,
) -> Vec<Module> {
    vec![
        build_user_module(user_session.clone()),
        build_workspace_module(&server_config, user_session, flowy_document),
    ]
}

fn build_user_module(user_session: Arc<UserSession>) -> Module { flowy_user::module::create(user_session.clone()) }

fn build_workspace_module(
    server_config: &ServerConfig,
    user_session: Arc<UserSession>,
    flowy_document: Arc<FlowyDocument>,
) -> Module {
    let workspace_deps = WorkspaceDepsResolver::new(user_session.clone());
    let (user, database) = workspace_deps.split_into();
    flowy_workspace::module::create(user, database, flowy_document, server_config)
}

pub fn build_document_module(user_session: Arc<UserSession>, server_config: &ServerConfig) -> Arc<FlowyDocument> {
    let document_deps = DocumentDepsResolver::new(user_session.clone());
    let (user, ws_manager) = document_deps.split_into();
    let document = Arc::new(FlowyDocument::new(user, ws_manager, server_config));
    document
}
