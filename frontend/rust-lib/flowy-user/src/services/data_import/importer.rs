use crate::services::data_import::appflowy_data_import::import_appflowy_data_folder;
use crate::services::entities::Session;
use collab_integrate::RocksCollabDB;

use flowy_folder_deps::entities::ImportData;
use std::sync::Arc;

pub enum ImportDataSource {
  AppFlowyDataFolder {
    path: String,
    container_name: String,
  },
}

pub(crate) fn import_data(
  session: &Session,
  source: ImportDataSource,
  collab_db: Arc<RocksCollabDB>,
) -> anyhow::Result<ImportData> {
  match source {
    ImportDataSource::AppFlowyDataFolder {
      path,
      container_name,
    } => import_appflowy_data_folder(session, path, container_name, &collab_db),
  }
}
