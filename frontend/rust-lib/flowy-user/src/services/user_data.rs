use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;

use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::ConnectionPool;

use crate::services::database::{collab_db_path_from_uid, user_db_path_from_uid};

pub struct UserDataMigration {}

impl UserDataMigration {
  pub fn migration(data_path: String, uid: i64) -> FlowyResult<()> {
    let dir = collab_db_path_from_uid(&data_path, uid);
    let collab_db =
      RocksCollabDB::open(dir).map_err(|err| FlowyError::new(ErrorCode::Internal, err))?;

    let read_txn = collab_db.read_txn();
    let names = read_txn.get_all_docs()?;
    for name in names {
      println!("name: {}", name);
    }
    Ok(())
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_migration() {
    let data_path = "/Users/zhengyuanbo/Downloads/flowy-data".to_string();
    let uid = 1;
    UserDataMigration::migration(data_path, uid).unwrap();
  }
}
