use crate::services::data_import::appflowy_data_import::import_appflowy_data_folder;
use crate::services::entities::Session;
use collab_integrate::RocksCollabDB;
use std::sync::Arc;

pub enum DataImportSource {
  AppFlowyDataFolder(String),
}

pub async fn import_data(
  session: &Session,
  source: DataImportSource,
  collab_db: Arc<RocksCollabDB>,
) {
  match source {
    DataImportSource::AppFlowyDataFolder(path) => {
      import_appflowy_data_folder(session, path, &collab_db).await;
    },
  }
}
