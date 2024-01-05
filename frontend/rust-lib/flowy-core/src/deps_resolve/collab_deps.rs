use std::sync::Weak;

use diesel::SqliteConnection;

use collab_integrate::{CollabSnapshot, PersistenceError, SnapshotPersistence};
use flowy_error::FlowyError;
use flowy_sqlite::{
  insert_or_ignore_into,
  prelude::*,
  schema::{collab_snapshot, collab_snapshot::dsl},
};
use flowy_user::manager::UserManager;
use lib_infra::util::timestamp;

pub struct SnapshotDBImpl(pub Weak<UserManager>);

impl SnapshotPersistence for SnapshotDBImpl {
  fn get_snapshots(&self, uid: i64, object_id: &str) -> Vec<CollabSnapshot> {
    match self.0.upgrade() {
      None => vec![],
      Some(user_session) => user_session
        .db_pool(uid)
        .and_then(|pool| Ok(pool.get()?))
        .and_then(|mut conn| {
          CollabSnapshotTableSql::get_all_snapshots(object_id, &mut conn)
            .map(|rows| rows.into_iter().map(|row| row.into()).collect())
        })
        .unwrap_or_else(|_| vec![]),
    }
  }

  fn create_snapshot(
    &self,
    uid: i64,
    object_id: &str,
    title: String,
    snapshot_data: Vec<u8>,
  ) -> Result<(), PersistenceError> {
    let object_id = object_id.to_string();
    let weak_user_session = self.0.clone();
    tokio::task::spawn_blocking(move || {
      if let Some(pool) = weak_user_session
        .upgrade()
        .and_then(|user_session| user_session.db_pool(uid).ok())
      {
        let mut conn = pool
          .get()
          .map_err(|e| PersistenceError::Internal(e.into()))?;

        // Save the snapshot data to disk
        let result = CollabSnapshotTableSql::create(
          CollabSnapshotRow {
            id: uuid::Uuid::new_v4().to_string(),
            object_id: object_id.clone(),
            title,
            desc: "".to_string(),
            collab_type: "".to_string(),
            timestamp: timestamp(),
            data: snapshot_data,
          },
          &mut conn,
        )
        .map_err(|e| PersistenceError::Internal(e.into()));

        if let Err(e) = result {
          tracing::warn!("create snapshot error: {:?}", e);
        }
      }
      Ok::<(), PersistenceError>(())
    });
    Ok(())
  }
}

#[derive(PartialEq, Clone, Debug, Queryable, Identifiable, Insertable)]
#[diesel(table_name = collab_snapshot)]
struct CollabSnapshotRow {
  id: String,
  object_id: String,
  title: String,
  desc: String,
  collab_type: String,
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
  fn create(row: CollabSnapshotRow, conn: &mut SqliteConnection) -> Result<(), FlowyError> {
    // Batch insert: https://diesel.rs/guides/all-about-inserts.html
    let values = (
      dsl::id.eq(row.id),
      dsl::object_id.eq(row.object_id),
      dsl::title.eq(row.title),
      dsl::desc.eq(row.desc),
      dsl::collab_type.eq(row.collab_type),
      dsl::data.eq(row.data),
      dsl::timestamp.eq(row.timestamp),
    );
    let _ = insert_or_ignore_into(dsl::collab_snapshot)
      .values(values)
      .execute(conn)?;
    Ok(())
  }

  fn get_all_snapshots(
    object_id: &str,
    conn: &mut SqliteConnection,
  ) -> Result<Vec<CollabSnapshotRow>, FlowyError> {
    let sql = dsl::collab_snapshot
      .filter(dsl::object_id.eq(object_id))
      .into_boxed();

    let rows = sql
      .order(dsl::timestamp.asc())
      .load::<CollabSnapshotRow>(conn)?;

    Ok(rows)
  }

  #[allow(dead_code)]
  fn get_latest_snapshot(
    object_id: &str,
    conn: &mut SqliteConnection,
  ) -> Option<CollabSnapshotRow> {
    let sql = dsl::collab_snapshot
      .filter(dsl::object_id.eq(object_id))
      .into_boxed();

    sql
      .order(dsl::timestamp.desc())
      .first::<CollabSnapshotRow>(conn)
      .ok()
  }

  #[allow(dead_code)]
  fn delete(
    object_id: &str,
    snapshot_ids: Option<Vec<String>>,
    conn: &mut SqliteConnection,
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
