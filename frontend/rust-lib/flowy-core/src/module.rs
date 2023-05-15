use std::sync::Arc;

use flowy_client_ws::FlowyWebSocketConnect;
use flowy_database2::DatabaseManager2;
use flowy_document::DocumentManager;
use flowy_document2::manager::DocumentManager as DocumentManager2;
use flowy_folder2::manager::Folder2Manager;
use flowy_user::services::UserSession;
use lib_dispatch::prelude::AFPlugin;

pub fn make_plugins(
  ws_conn: &Arc<FlowyWebSocketConnect>,
  folder_manager: &Arc<Folder2Manager>,
  database_manager: &Arc<DatabaseManager2>,
  user_session: &Arc<UserSession>,
  document_manager: &Arc<DocumentManager>,
  document_manager2: &Arc<DocumentManager2>,
) -> Vec<AFPlugin> {
  let user_plugin = flowy_user::event_map::init(user_session.clone());
  let folder_plugin = flowy_folder2::event_map::init(folder_manager.clone());
  let network_plugin = flowy_net::event_map::init(ws_conn.clone());
  let database_plugin = flowy_database2::event_map::init(database_manager.clone());
  let document_plugin = flowy_document::event_map::init(document_manager.clone());
  let document_plugin2 = flowy_document2::event_map::init(document_manager2.clone());
  vec![
    user_plugin,
    folder_plugin,
    network_plugin,
    database_plugin,
    document_plugin,
    document_plugin2,
  ]
}
