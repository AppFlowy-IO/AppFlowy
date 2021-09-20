use flowy_dispatch::prelude::Module;

use crate::deps_resolve::{DocumentDepsResolver, WorkspaceDepsResolver};
use flowy_document::module::FlowyDocument;
use flowy_user::services::user::{UserSession, UserSessionBuilder};

use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig) -> Vec<Module> {
    let user_session = Arc::new(UserSessionBuilder::new().root_dir(&config.root).build());
    vec![build_user_module(user_session.clone()), build_workspace_module(user_session)]
}

fn build_user_module(user_session: Arc<UserSession>) -> Module { flowy_user::module::create(user_session.clone()) }

fn build_workspace_module(user_session: Arc<UserSession>) -> Module {
    let workspace_deps = WorkspaceDepsResolver::new(user_session.clone());
    let (user, database) = workspace_deps.split_into();
    let document = build_document_module(user_session.clone());

    flowy_workspace::module::create(user, database, document)
}

fn build_document_module(user_session: Arc<UserSession>) -> Arc<FlowyDocument> {
    let document_deps = DocumentDepsResolver::new(user_session.clone());
    let (user, ws) = document_deps.split_into();
    let document = Arc::new(FlowyDocument::new(user, ws));
    document
}
