use flowy_block::BlockManager;
use flowy_folder::manager::FolderManager;
use flowy_grid::manager::GridManager;
use flowy_net::ws::connection::FlowyWebSocketConnect;
use flowy_user::services::UserSession;
use lib_dispatch::prelude::Module;
use std::sync::Arc;

pub fn mk_modules(
    ws_conn: &Arc<FlowyWebSocketConnect>,
    folder_manager: &Arc<FolderManager>,
    grid_manager: &Arc<GridManager>,
    user_session: &Arc<UserSession>,
    block_manager: &Arc<BlockManager>,
) -> Vec<Module> {
    let user_module = mk_user_module(user_session.clone());
    let folder_module = mk_folder_module(folder_manager.clone());
    let network_module = mk_network_module(ws_conn.clone());
    let grid_module = mk_grid_module(grid_manager.clone());
    let block_module = mk_block_module(block_manager.clone());
    vec![user_module, folder_module, network_module, grid_module, block_module]
}

fn mk_user_module(user_session: Arc<UserSession>) -> Module {
    flowy_user::event_map::create(user_session)
}

fn mk_folder_module(folder_manager: Arc<FolderManager>) -> Module {
    flowy_folder::event_map::create(folder_manager)
}

fn mk_network_module(ws_conn: Arc<FlowyWebSocketConnect>) -> Module {
    flowy_net::event_map::create(ws_conn)
}

fn mk_grid_module(grid_manager: Arc<GridManager>) -> Module {
    flowy_grid::event_map::create(grid_manager)
}

fn mk_block_module(block_manager: Arc<BlockManager>) -> Module {
    flowy_block::event_map::create(block_manager)
}
