use flowy_document::DocumentManager;
use flowy_folder::manager::FolderManager;
use flowy_grid::manager::GridManager;
use flowy_net::ws::connection::FlowyWebSocketConnect;
use flowy_user::services::UserSession;
use lib_dispatch::prelude::AFPlugin;
use std::sync::Arc;

pub fn make_plugins(
    ws_conn: &Arc<FlowyWebSocketConnect>,
    folder_manager: &Arc<FolderManager>,
    grid_manager: &Arc<GridManager>,
    user_session: &Arc<UserSession>,
    document_manager: &Arc<DocumentManager>,
) -> Vec<AFPlugin> {
    let user_plugin = flowy_user::event_map::init(user_session.clone());
    let folder_plugin = flowy_folder::event_map::init(folder_manager.clone());
    let network_plugin = flowy_net::event_map::init(ws_conn.clone());
    let grid_plugin = flowy_grid::event_map::init(grid_manager.clone());
    let document_plugin = flowy_document::event_map::init(document_manager.clone());
    vec![user_plugin, folder_plugin, network_plugin, grid_plugin, document_plugin]
}
