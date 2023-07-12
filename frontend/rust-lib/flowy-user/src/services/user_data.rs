use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

use appflowy_integrate::{RocksCollabDB, YrsDocAction};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::ConnectionPool;

use crate::services::database::{collab_db_path_from_uid, user_db_path_from_uid};

pub struct UserDataMigration();

impl UserDataMigration {
  pub fn migration(uid: i64, collab_db: &RocksCollabDB) -> FlowyResult<MigrationCollabData> {
    let mut migration_data = MigrationCollabData {
      objects: HashMap::new(),
    };
    let read_txn = collab_db.read_txn();
    if let Ok(mut object_ids) = read_txn.get_all_docs() {
      while let Some(object_id) = object_ids.next() {
        if let Ok(updates) = read_txn.get_all_updates(uid, &object_id) {
          migration_data.objects.insert(object_id, updates);
        }
      }
    }
    Ok(migration_data)
  }
}

fn open_collab_db(uid: i64, root: String) -> FlowyResult<RocksCollabDB> {
  let dir = collab_db_path_from_uid(&root, uid);
  RocksCollabDB::open(dir).map_err(|err| FlowyError::new(ErrorCode::Internal, err))
}

pub struct MigrationCollabData {
  pub objects: HashMap<String, Vec<Vec<u8>>>,
}
