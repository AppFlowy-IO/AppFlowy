use flowy_core::controller::FolderManager;
use flowy_net::ws::connection::FlowyWebSocketConnect;
use flowy_user::services::UserSession;
use lib_dispatch::prelude::Module;
use std::sync::Arc;

pub fn mk_modules(
    ws_conn: &Arc<FlowyWebSocketConnect>,
    folder_manager: &Arc<FolderManager>,
    user_session: &Arc<UserSession>,
) -> Vec<Module> {
    let user_module = mk_user_module(user_session.clone());
    let folder_module = mk_folder_module(folder_manager.clone());
    let network_module = mk_network_module(ws_conn.clone());
    vec![user_module, folder_module, network_module]
}

fn mk_user_module(user_session: Arc<UserSession>) -> Module { flowy_user::module::create(user_session) }

fn mk_folder_module(core: Arc<FolderManager>) -> Module { flowy_core::module::create(core) }

fn mk_network_module(ws_conn: Arc<FlowyWebSocketConnect>) -> Module { flowy_net::module::create(ws_conn) }
