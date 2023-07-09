use std::sync::Arc;

use flowy_database2::DatabaseManager2;
use flowy_document2::manager::DocumentManager as DocumentManager2;
use flowy_folder2::manager::FolderManager;
use flowy_user::services::UserSession;
use lib_dispatch::prelude::AFPlugin;

pub fn make_plugins(
  folder_manager: &Arc<FolderManager>,
  database_manager: &Arc<DatabaseManager2>,
  user_session: &Arc<UserSession>,
  document_manager2: &Arc<DocumentManager2>,
) -> Vec<AFPlugin> {
  let user_plugin = flowy_user::event_map::init(user_session.clone());
  let folder_plugin = flowy_folder2::event_map::init(folder_manager.clone());
  let network_plugin = flowy_net::event_map::init();
  let database_plugin = flowy_database2::event_map::init(database_manager.clone());
  let document_plugin2 = flowy_document2::event_map::init(document_manager2.clone());
  let config_plugin = flowy_config::event_map::init();
  vec![
    user_plugin,
    folder_plugin,
    network_plugin,
    database_plugin,
    document_plugin2,
    config_plugin,
  ]
}
