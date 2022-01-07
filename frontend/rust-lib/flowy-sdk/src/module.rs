use flowy_core::context::CoreContext;
use flowy_net::services::ws_conn::FlowyWebSocketConnect;
use flowy_user::services::user::UserSession;
use lib_dispatch::prelude::Module;
use std::sync::Arc;

pub fn mk_modules(
    ws_conn: &Arc<FlowyWebSocketConnect>,
    core: &Arc<CoreContext>,
    user_session: &Arc<UserSession>,
) -> Vec<Module> {
    let user_module = mk_user_module(user_session.clone());
    let core_module = mk_core_module(core.clone());
    let network_module = mk_network_module(ws_conn.clone());
    vec![user_module, core_module, network_module]
}

fn mk_user_module(user_session: Arc<UserSession>) -> Module { flowy_user::module::create(user_session) }

fn mk_core_module(core: Arc<CoreContext>) -> Module { flowy_core::module::create(core) }

fn mk_network_module(ws_conn: Arc<FlowyWebSocketConnect>) -> Module { flowy_net::module::create(ws_conn) }
