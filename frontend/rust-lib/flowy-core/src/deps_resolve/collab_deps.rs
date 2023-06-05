use std::sync::Arc;

use appflowy_integrate::{
  try_encode_snapshot, CollabSnapshot, MutexCollab, PersistenceError, SnapshotDB,
};
use diesel::SqliteConnection;

use flowy_error::FlowyError;
use flowy_sqlite::{
  impl_sql_integer_expression, insert_or_ignore_into,
  prelude::*,
  schema::{collab_snapshot, collab_snapshot::dsl},
  ConnectionPool,
};
use flowy_user::services::UserSession;
use lib_infra::util::timestamp;

pub struct SnapshotDBImpl {
  user_session: Arc<UserSession>,
}

impl SnapshotDB for SnapshotDBImpl {
  fn get_snapshots(&self, _uid: i64, object_id: &str) -> Vec<CollabSnapshot> {
    match self.user_session.db_pool() {
      Ok(pool) => match pool.get() {
        Ok(conn) => {
          let rows = CollabSnapshotTableSql::read_snapshots(object_id, &conn).unwrap();
          rows.into_iter().map(|row| row.into()).collect()
        },
        Err(_) => vec![],
      },
      Err(_) => vec![],
    }
  }

  fn create_snapshot(
    &self,
    _uid: i64,
    object_id: &str,
    collab: Arc<MutexCollab>,
  ) -> Result<(), PersistenceError> {
    let object_id = object_id.to_string();
    let pool = self
      .user_session
      .db_pool()
      .map_err(|_| PersistenceError::InternalError)?;

    let _ = tokio::task::spawn_blocking(move || {
      let conn = pool.get()?;
      let result = try_encode_snapshot(&collab.lock().transact());
      match result {
        Ok(data) => {
          if let Err(e) = CollabSnapshotTableSql::create(
            CollabSnapshotRow {
              id: uuid::Uuid::new_v4().to_string(),
              object_id,
              desc: "".to_string(),
              timestamp: timestamp(),
              data,
            },
            &conn,
          ) {
            tracing::error!("create snapshot error: {:?}", e);
          }
        },
        Err(e) => {
          tracing::error!("Failed to encode snapshot: {:?}", e);
        },
      }
      Ok::<(), FlowyError>(())
    });
    Ok(())
  }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable, Associations)]
#[table_name = "collab_snapshot"]
struct CollabSnapshotRow {
  id: String,
  object_id: String,
  desc: String,
  timestamp: i64,
  data: Vec<u8>,
}

impl From<CollabSnapshotRow> for CollabSnapshot {
  fn from(table: CollabSnapshotRow) -> Self {
    Self {
      data: table.data,
      created_at: table.timestamp,
    }
  }
}

struct CollabSnapshotTableSql;
impl CollabSnapshotTableSql {
  fn create(row: CollabSnapshotRow, conn: &SqliteConnection) -> Result<(), FlowyError> {
    // Batch insert: https://diesel.rs/guides/all-about-inserts.html
    let values = (
      dsl::id.eq(row.id),
      dsl::object_id.eq(row.object_id),
      dsl::desc.eq(row.desc),
      dsl::data.eq(row.data),
      dsl::timestamp.eq(row.timestamp),
    );
    let _ = insert_or_ignore_into(dsl::collab_snapshot)
      .values(values)
      .execute(conn)?;
    Ok(())
  }

  fn read_snapshots(
    object_id: &str,
    conn: &SqliteConnection,
  ) -> Result<Vec<CollabSnapshotRow>, FlowyError> {
    let sql = dsl::collab_snapshot
      .filter(dsl::object_id.eq(object_id))
      .into_boxed();

    let rows = sql
      .order(dsl::timestamp.asc())
      .load::<CollabSnapshotRow>(conn)?;

    Ok(rows)
  }

  fn delete(
    object_id: &str,
    snapshot_ids: Option<Vec<String>>,
    conn: &SqliteConnection,
  ) -> Result<(), FlowyError> {
    let mut sql = diesel::delete(dsl::collab_snapshot).into_boxed();
    sql = sql.filter(dsl::object_id.eq(object_id));

    if let Some(snapshot_ids) = snapshot_ids {
      tracing::trace!(
        "[{}] Delete snapshot: {}:{:?}",
        std::any::type_name::<Self>(),
        object_id,
        snapshot_ids
      );
      sql = sql.filter(dsl::id.eq_any(snapshot_ids));
    }

    let affected_row = sql.execute(conn)?;
    tracing::trace!(
      "[{}] Delete {} rows",
      std::any::type_name::<Self>(),
      affected_row
    );
    Ok(())
  }
}
