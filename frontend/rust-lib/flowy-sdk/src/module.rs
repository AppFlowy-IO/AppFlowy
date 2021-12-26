use flowy_core::prelude::CoreContext;

use flowy_net::services::ws::FlowyWSConnect;
use flowy_user::services::user::UserSession;
use lib_dispatch::prelude::Module;
use std::sync::Arc;

pub fn mk_modules(
    ws_manager: Arc<FlowyWSConnect>,
    core: Arc<CoreContext>,
    user_session: Arc<UserSession>,
) -> Vec<Module> {
    let user_module = mk_user_module(user_session);
    let core_module = mk_core_module(core);
    let network_module = mk_network_module(ws_manager);
    vec![user_module, core_module, network_module]
}

fn mk_user_module(user_session: Arc<UserSession>) -> Module { flowy_user::module::create(user_session) }

fn mk_core_module(core: Arc<CoreContext>) -> Module { flowy_core::module::create(core) }

fn mk_network_module(ws_manager: Arc<FlowyWSConnect>) -> Module { flowy_net::module::create(ws_manager) }
