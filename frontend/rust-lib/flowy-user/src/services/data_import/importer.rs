use crate::services::data_import::appflowy_data_import::import_appflowy_data_folder;
use collab_integrate::{CollabKVAction, CollabKVDB, PersistenceError};
use flowy_user_pub::session::Session;
use std::collections::HashMap;

use crate::services::data_import::ImportContext;
use collab::preclude::Collab;
use flowy_folder_pub::entities::ImportData;
use std::sync::Arc;
use tracing::instrument;

/// Import appflowy data from the given path.
/// If the container name is not empty, then the data will be imported to the given container.
/// Otherwise, the data will be imported to the current workspace.
pub(crate) fn import_data(
  session: &Session,
  context: ImportContext,
  collab_db: Arc<CollabKVDB>,
) -> anyhow::Result<ImportData> {
  import_appflowy_data_folder(session, &session.user_workspace.id, &collab_db, context)
}

#[instrument(level = "debug", skip_all)]
pub fn load_collab_by_oid<'a, R>(
  uid: i64,
  collab_read_txn: &R,
  object_ids: &[String],
) -> HashMap<String, Collab>
where
  R: CollabKVAction<'a>,
  PersistenceError: From<R::Error>,
{
  let mut collab_by_oid = HashMap::new();
  for object_id in object_ids {
    let collab = Collab::new(uid, object_id, "phantom", vec![], false);
    match collab
      .with_origin_transact_mut(|txn| collab_read_txn.load_doc_with_txn(uid, &object_id, txn))
    {
      Ok(_) => {
        collab_by_oid.insert(object_id.clone(), collab);
      },
      Err(err) => tracing::error!("🔴import collab:{} failed: {:?} ", object_id, err),
    }
  }

  collab_by_oid
}
