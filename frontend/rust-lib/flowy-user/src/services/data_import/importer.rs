use crate::services::data_import::appflowy_data_import::import_appflowy_data_folder;
use crate::services::entities::Session;
use collab_integrate::{PersistenceError, RocksCollabDB, YrsDocAction};
use std::collections::HashMap;

use collab::preclude::Collab;
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

pub fn load_collab_by_oid<'a, R>(
  uid: i64,
  collab_read_txn: &R,
  object_ids: &[String],
) -> HashMap<String, Collab>
where
  R: YrsDocAction<'a>,
  PersistenceError: From<R::Error>,
{
  let mut collab_by_oid = HashMap::new();
  for object_id in object_ids {
    let collab = Collab::new(uid, object_id, "phantom", vec![]);
    match collab
      .with_origin_transact_mut(|txn| collab_read_txn.load_doc_with_txn(uid, &object_id, txn))
    {
      Ok(_) => {
        collab_by_oid.insert(object_id.clone(), collab);
      },
      Err(err) => tracing::error!("🔴Initialize migration collab failed: {:?} ", err),
    }
  }

  collab_by_oid
}
