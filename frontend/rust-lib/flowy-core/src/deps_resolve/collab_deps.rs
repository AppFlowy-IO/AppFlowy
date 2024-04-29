use collab_entity::CollabType;
use collab_integrate::{CollabSnapshot, PersistenceError, SnapshotPersistence};
use diesel::dsl::count_star;
use diesel::SqliteConnection;
use flowy_error::FlowyError;
use flowy_sqlite::{
  prelude::*,
  schema::{collab_snapshot, collab_snapshot::dsl},
};
use flowy_user::services::authenticate_user::AuthenticateUser;

use collab_integrate::collab_builder::WorkspaceCollabIntegrate;
use lib_infra::util::timestamp;
use std::sync::{Arc, Weak};
use tracing::debug;

pub struct SnapshotDBImpl(pub Weak<AuthenticateUser>);

impl SnapshotPersistence for SnapshotDBImpl {
  fn create_snapshot(
    &self,
    uid: i64,
    object_id: &str,
    collab_type: &CollabType,
    encoded_v1: Vec<u8>,
  ) -> Result<(), PersistenceError> {
    let collab_type = collab_type.clone();
    let object_id = object_id.to_string();
    let weak_user = self.0.clone();
    tokio::task::spawn_blocking(move || {
      if let Some(mut conn) = weak_user
        .upgrade()
        .and_then(|authenticate_user| authenticate_user.get_sqlite_connection(uid).ok())
      {
        // Save the snapshot data to disk
        let result = CollabSnapshotSql::create(
          CollabSnapshotRow::new(object_id.clone(), collab_type.to_string(), encoded_v1),
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
pub(crate) struct CollabSnapshotRow {
  pub(crate) id: String,
  object_id: String,
  title: String,
  desc: String,
  collab_type: String,
  pub(crate) timestamp: i64,
  pub(crate) data: Vec<u8>,
}

impl CollabSnapshotRow {
  pub fn new(object_id: String, collab_type: String, data: Vec<u8>) -> Self {
    Self {
      id: uuid::Uuid::new_v4().to_string(),
      object_id,
      title: "".to_string(),
      desc: "".to_string(),
      collab_type,
      timestamp: timestamp(),
      data,
    }
  }
}

impl From<CollabSnapshotRow> for CollabSnapshot {
  fn from(table: CollabSnapshotRow) -> Self {
    Self {
      data: table.data,
      created_at: table.timestamp,
    }
  }
}

pub struct CollabSnapshotMeta {
  pub id: String,
  pub object_id: String,
  pub timestamp: i64,
}

pub(crate) struct CollabSnapshotSql;
impl CollabSnapshotSql {
  pub(crate) fn create(
    row: CollabSnapshotRow,
    conn: &mut SqliteConnection,
  ) -> Result<(), FlowyError> {
    conn.immediate_transaction::<_, Error, _>(|conn| {
      // Insert the new snapshot
      insert_into(dsl::collab_snapshot)
        .values((
          dsl::id.eq(row.id),
          dsl::object_id.eq(&row.object_id),
          dsl::title.eq(row.title),
          dsl::desc.eq(row.desc),
          dsl::collab_type.eq(row.collab_type),
          dsl::data.eq(row.data),
          dsl::timestamp.eq(row.timestamp),
        ))
        .execute(conn)?;

      // Count the total number of snapshots for the specific object_id
      let total_snapshots: i64 = dsl::collab_snapshot
        .filter(dsl::object_id.eq(&row.object_id))
        .select(count_star())
        .first(conn)?;

      // If there are more than 5 snapshots, delete the oldest one
      if total_snapshots > 5 {
        let ids_to_delete: Vec<String> = dsl::collab_snapshot
          .filter(dsl::object_id.eq(&row.object_id))
          .order(dsl::timestamp.asc())
          .select(dsl::id)
          .limit(1)
          .load(conn)?;

        debug!(
          "Delete {} snapshots for object_id: {}",
          ids_to_delete.len(),
          row.object_id
        );
        for id in ids_to_delete {
          delete(dsl::collab_snapshot.filter(dsl::id.eq(id))).execute(conn)?;
        }
      }

      Ok(())
    })?;
    Ok(())
  }

  pub(crate) fn get_all_snapshots(
    object_id: &str,
    conn: &mut SqliteConnection,
  ) -> Result<Vec<CollabSnapshotMeta>, FlowyError> {
    let results = collab_snapshot::table
      .filter(collab_snapshot::object_id.eq(object_id))
      .select((
        collab_snapshot::id,
        collab_snapshot::object_id,
        collab_snapshot::timestamp,
      ))
      .load::<(String, String, i64)>(conn)
      .expect("Error loading collab_snapshot");

    // Map the results to CollabSnapshotMeta
    let snapshots: Vec<CollabSnapshotMeta> = results
      .into_iter()
      .map(|(id, object_id, timestamp)| CollabSnapshotMeta {
        id,
        object_id,
        timestamp,
      })
      .collect();

    Ok(snapshots)
  }

  pub(crate) fn get_snapshot(
    object_id: &str,
    conn: &mut SqliteConnection,
  ) -> Option<CollabSnapshotRow> {
    let sql = dsl::collab_snapshot
      .filter(dsl::id.eq(object_id))
      .into_boxed();

    sql
      .order(dsl::timestamp.desc())
      .first::<CollabSnapshotRow>(conn)
      .ok()
  }

  #[allow(dead_code)]
  pub(crate) fn delete(
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

pub(crate) struct WorkspaceCollabIntegrateImpl(pub Weak<AuthenticateUser>);

impl WorkspaceCollabIntegrateImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl WorkspaceCollabIntegrate for WorkspaceCollabIntegrateImpl {
  fn workspace_id(&self) -> Result<String, anyhow::Error> {
    let workspace_id = self.upgrade_user()?.workspace_id()?;
    Ok(workspace_id)
  }

  fn device_id(&self) -> Result<String, anyhow::Error> {
    Ok(self.upgrade_user()?.user_config.device_id.clone())
  }
}
