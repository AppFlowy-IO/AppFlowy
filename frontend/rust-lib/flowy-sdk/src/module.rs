use crate::deps_resolve::DocumentDepsResolver;
use backend_service::configuration::ClientServerConfiguration;
use flowy_core::prelude::CoreContext;
use flowy_document::module::FlowyDocument;
use flowy_user::services::user::UserSession;
use lib_dispatch::prelude::Module;
use std::sync::Arc;

pub fn mk_modules(core: Arc<CoreContext>, user_session: Arc<UserSession>) -> Vec<Module> {
    let user_module = mk_user_module(user_session);
    let workspace_module = mk_core_module(core);
    vec![user_module, workspace_module]
}

fn mk_user_module(user_session: Arc<UserSession>) -> Module { flowy_user::module::create(user_session) }
fn mk_core_module(core: Arc<CoreContext>) -> Module { flowy_core::module::create(core) }

pub fn mk_document_module(
    user_session: Arc<UserSession>,
    server_config: &ClientServerConfiguration,
) -> Arc<FlowyDocument> {
    let document_deps = DocumentDepsResolver::new(user_session);
    let (user, ws_manager) = document_deps.split_into();
    Arc::new(FlowyDocument::new(user, ws_manager, server_config))
}
