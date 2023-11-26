use std::sync::{Arc, Weak};

use collab::core::collab_plugin::EncodedCollabV1;
use collab_plugins::local_storage::rocksdb::RocksdbBackup;
use diesel::SqliteConnection;

use flowy_error::FlowyError;
use flowy_sqlite::{prelude::*, schema::rocksdb_backup, schema::rocksdb_backup::dsl};
use flowy_user::manager::UserManager;
use lib_infra::util::timestamp;

pub struct RocksdbBackupImpl(pub Weak<UserManager>);

impl RocksdbBackupImpl {
  fn get_pool(&self, uid: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .db_pool(uid)
  }
}

impl RocksdbBackup for RocksdbBackupImpl {
  fn save_doc(
    &self,
    uid: i64,
    object_id: &str,
    data: EncodedCollabV1,
  ) -> Result<(), anyhow::Error> {
    let row = RocksdbBackupRow {
      object_id: object_id.to_string(),
      timestamp: timestamp(),
      data: data.encode_to_bytes().unwrap_or_default().to_vec(),
    };

    self
      .get_pool(uid)
      .map(|pool| RocksdbBackupTableSql::create(row, &*pool.get()?))??;
    Ok(())
  }

  fn get_doc(&self, uid: i64, object_id: &str) -> Result<EncodedCollabV1, anyhow::Error> {
    let sql = dsl::rocksdb_backup
      .filter(dsl::object_id.eq(object_id))
      .into_boxed();

    let pool = self.get_pool(uid)?;
    let row = pool
      .get()
      .map(|conn| sql.first::<RocksdbBackupRow>(&*conn))??;

    Ok(EncodedCollabV1::decode_from_bytes(&row.data)?)
  }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "rocksdb_backup"]
#[primary_key(object_id)]
struct RocksdbBackupRow {
  object_id: String,
  timestamp: i64,
  data: Vec<u8>,
}

struct RocksdbBackupTableSql;
impl RocksdbBackupTableSql {
  fn create(row: RocksdbBackupRow, conn: &SqliteConnection) -> Result<(), FlowyError> {
    let _ = replace_into(dsl::rocksdb_backup)
      .values(&row)
      .execute(conn)?;
    Ok(())
  }

  #[allow(dead_code)]
  fn get_row(object_id: &str, conn: &SqliteConnection) -> Result<RocksdbBackupRow, FlowyError> {
    let sql = dsl::rocksdb_backup
      .filter(dsl::object_id.eq(object_id))
      .into_boxed();

    let row = sql.first::<RocksdbBackupRow>(conn)?;
    Ok(row)
  }
}
