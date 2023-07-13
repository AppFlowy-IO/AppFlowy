use std::collections::HashMap;
use std::sync::Arc;

use appflowy_integrate::{PersistenceError, RocksCollabDB, YrsDocAction};
use collab::core::origin::{CollabClient, CollabOrigin};
use collab::error::CollabError;
use collab::preclude::Collab;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

pub struct UserDataMigration();

impl UserDataMigration {
  pub fn migration(
    old_uid: i64,
    old_collab_db: &Arc<RocksCollabDB>,
    new_uid: i64,
    new_collab_db: &Arc<RocksCollabDB>,
  ) -> FlowyResult<()> {
    new_collab_db
      .with_write_txn(|w_txn| {
        let read_txn = old_collab_db.read_txn();
        if let Ok(mut object_ids) = read_txn.get_all_docs() {
          // Migration of all objects
          while let Some(object_id) = object_ids.next() {
            tracing::debug!("migrate object: {:?}", object_id);
            if let Ok(updates) = read_txn.get_all_updates(old_uid, &object_id) {
              let origin = CollabOrigin::Client(CollabClient::new(new_uid, ""));
              match Collab::new_with_raw_data(origin, &object_id, updates, vec![]) {
                Ok(collab) => {
                  let txn = collab.transact();
                  if let Err(err) = w_txn.create_new_doc(new_uid, &object_id, &txn) {
                    tracing::error!("🔴migrate collab failed: {:?}", err);
                  }
                },
                Err(err) => tracing::error!("🔴construct migration collab failed: {:?} ", err),
              }
            }
          }
        }
        Ok(())
      })
      .map_err(|err| FlowyError::new(ErrorCode::Internal, err))
  }
}

// fn open_collab_db(uid: i64, root: String) -> FlowyResult<RocksCollabDB> {
//   let dir = collab_db_path_from_uid(&root, uid);
//   RocksCollabDB::open(dir).map_err(|err| FlowyError::new(ErrorCode::Internal, err))
// }
