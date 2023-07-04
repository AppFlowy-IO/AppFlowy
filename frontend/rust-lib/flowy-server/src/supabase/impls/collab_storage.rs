use std::sync::{Arc, Weak};

use anyhow::Error;
use appflowy_integrate::{
  merge_updates_v1, CollabObject, Decode, MsgId, RemoteCollabSnapshot, RemoteCollabState,
  RemoteCollabStorage, YrsUpdate,
};
use chrono::{DateTime, Utc};
use deadpool_postgres::GenericClient;
use futures_util::TryStreamExt;
use tokio::task::spawn_blocking;
use tokio_postgres::types::ToSql;
use tokio_postgres::Row;

use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;

use crate::supabase::sql_builder::{
  DeleteSqlBuilder, InsertSqlBuilder, SelectSqlBuilder, WhereCondition,
};
use crate::supabase::PostgresServer;

pub struct PgCollabStorageImpl {
  server: Arc<PostgresServer>,
}

const AF_COLLAB_KEY_COLUMN: &str = "key";
const AF_COLLAB_SNAPSHOT_OID_COLUMN: &str = "oid";
const AF_COLLAB_SNAPSHOT_ID_COLUMN: &str = "sid";
const AF_COLLAB_SNAPSHOT_BLOB_COLUMN: &str = "blob";
const AF_COLLAB_SNAPSHOT_BLOB_SIZE_COLUMN: &str = "blob_size";
const AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN: &str = "created_at";
const AF_COLLAB_SNAPSHOT_TABLE: &str = "af_collab_snapshot";

impl PgCollabStorageImpl {
  pub fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

#[async_trait]
impl RemoteCollabStorage for PgCollabStorageImpl {
  async fn get_all_updates(&self, object_id: &str) -> Result<Vec<Vec<u8>>, Error> {
    get_updates_from_server(object_id, Arc::downgrade(&self.server)).await
  }

  async fn get_latest_snapshot(
    &self,
    object_id: &str,
  ) -> Result<Option<RemoteCollabSnapshot>, Error> {
    get_latest_snapshot_from_server(object_id, Arc::downgrade(&self.server)).await
  }

  async fn get_collab_state(&self, object_id: &str) -> Result<Option<RemoteCollabState>, Error> {
    let client = self.server.get_pg_client().await.recv().await?;
    let (sql, params) = SelectSqlBuilder::new("af_collab_state")
      .column("*")
      .where_clause("oid", object_id.to_string())
      .order_by("snapshot_created_at", false)
      .limit(1)
      .build();
    let stmt = client.prepare_cached(&sql).await?;
    if let Some(row) = client
      .query_raw(&stmt, params)
      .await?
      .try_collect::<Vec<_>>()
      .await?
      .first()
    {
      let created_at = row.try_get::<&str, DateTime<Utc>>("snapshot_created_at")?;
      let current_edit_count = row.try_get::<_, i64>("current_edit_count")?;
      let last_snapshot_edit_count = row.try_get::<_, i64>("snapshot_edit_count")?;

      let state = RemoteCollabState {
        current_edit_count,
        last_snapshot_edit_count,
        last_snapshot_created_at: created_at.timestamp(),
      };
      return Ok(Some(state));
    }

    Ok(None)
  }

  async fn create_snapshot(&self, object: &CollabObject, snapshot: Vec<u8>) -> Result<i64, Error> {
    let client = self.server.get_pg_client().await.recv().await?;
    let value_size = snapshot.len() as i32;
    let (sql, params) = InsertSqlBuilder::new("af_collab_snapshot")
      .value(AF_COLLAB_SNAPSHOT_OID_COLUMN, object.id.clone())
      .value("name", object.name.clone())
      .value(AF_COLLAB_SNAPSHOT_BLOB_COLUMN, snapshot)
      .value(AF_COLLAB_SNAPSHOT_BLOB_SIZE_COLUMN, value_size)
      .returning(AF_COLLAB_SNAPSHOT_ID_COLUMN)
      .build();
    let stmt = client.prepare_cached(&sql).await?;

    let all_rows = client
      .query_raw(&stmt, params)
      .await?
      .try_collect::<Vec<_>>()
      .await?;
    let row = all_rows
      .first()
      .ok_or(anyhow::anyhow!("Create snapshot failed. No row returned"))?;
    let sid = row.try_get::<&str, i64>(AF_COLLAB_SNAPSHOT_ID_COLUMN)?;
    return Ok(sid);
  }

  async fn send_update(
    &self,
    object: &CollabObject,
    _id: MsgId,
    update: Vec<u8>,
  ) -> Result<(), Error> {
    let client = self.server.get_pg_client().await.recv().await?;
    let value_size = update.len() as i32;
    let (sql, params) = InsertSqlBuilder::new("af_collab")
      .value("oid", object.id.clone())
      .value("name", object.name.clone())
      .value("value", update)
      .value("value_size", value_size)
      .build();

    let stmt = client.prepare_cached(&sql).await?;
    client.execute_raw(&stmt, params).await?;
    Ok(())
  }

  async fn send_init_sync(
    &self,
    object: &CollabObject,
    _id: MsgId,
    init_update: Vec<u8>,
  ) -> Result<(), Error> {
    let mut client = self.server.get_pg_client().await.recv().await?;
    let txn = client.transaction().await?;

    // 1.Get all updates
    let (sql, params) = SelectSqlBuilder::new("af_collab")
      .column(AF_COLLAB_KEY_COLUMN)
      .column("value")
      .order_by(AF_COLLAB_KEY_COLUMN, true)
      .where_clause("oid", object.id.clone())
      .build();
    let get_all_update_stmt = txn.prepare_cached(&sql).await?;
    let row_stream = txn.query_raw(&get_all_update_stmt, params).await?;
    let remote_updates = row_stream.try_collect::<Vec<_>>().await?;

    let insert_builder = InsertSqlBuilder::new("af_collab")
      .value("oid", object.id.clone())
      .value("name", object.name.clone());

    let (sql, params) = if !remote_updates.is_empty() {
      let remoted_keys = remote_updates
        .iter()
        .map(|row| row.get::<_, i64>(AF_COLLAB_KEY_COLUMN))
        .collect::<Vec<_>>();
      let last_row_key = remoted_keys.last().cloned().unwrap();

      // 2.Merge all updates
      let merged_update =
        spawn_blocking(move || merge_update_from_rows(remote_updates, init_update)).await??;

      // 3. Delete all updates
      let (sql, params) = DeleteSqlBuilder::new("af_collab")
        .where_condition(WhereCondition::Equals(
          "oid".to_string(),
          Box::new(object.id.clone()),
        ))
        .where_condition(WhereCondition::In(
          AF_COLLAB_KEY_COLUMN.to_string(),
          remoted_keys
            .into_iter()
            .map(|key| Box::new(key) as Box<dyn ToSql + Send + Sync>)
            .collect::<Vec<_>>(),
        ))
        .build();
      let delete_stmt = txn.prepare_cached(&sql).await?;
      txn.execute_raw(&delete_stmt, params).await?;

      let value_size = merged_update.len() as i32;
      // Override the key with the last row key in case of concurrent init sync
      insert_builder
        .value("value", merged_update)
        .value("value_size", value_size)
        .value(AF_COLLAB_KEY_COLUMN, last_row_key)
        .overriding_system_value()
        .build()
    } else {
      let value_size = init_update.len() as i32;
      insert_builder
        .value("value", init_update)
        .value("value_size", value_size)
        .build()
    };

    // 4.Insert the merged update
    let stmt = txn.prepare_cached(&sql).await?;
    txn.execute_raw(&stmt, params).await?;

    // 4.commit the transaction
    txn.commit().await?;
    tracing::trace!("{} init sync done", object.id);
    Ok(())
  }
}

pub async fn get_updates_from_server(
  object_id: &str,
  server: Weak<PostgresServer>,
) -> Result<Vec<Vec<u8>>, Error> {
  match server.upgrade() {
    None => Ok(vec![]),
    Some(server) => {
      let client = server.get_pg_client().await.recv().await?;
      let (sql, params) = SelectSqlBuilder::new("af_collab")
        .column("value")
        .order_by(AF_COLLAB_KEY_COLUMN, true)
        .where_clause("oid", object_id.to_string())
        .build();
      let stmt = client.prepare_cached(&sql).await?;
      let row_stream = client.query_raw(&stmt, params).await?;
      Ok(
        row_stream
          .try_collect::<Vec<_>>()
          .await?
          .into_iter()
          .flat_map(|row| update_from_row(row).ok())
          .collect(),
      )
    },
  }
}

pub async fn get_latest_snapshot_from_server(
  object_id: &str,
  server: Weak<PostgresServer>,
) -> Result<Option<RemoteCollabSnapshot>, Error> {
  match server.upgrade() {
    None => Ok(None),
    Some(server) => {
      let client = server.get_pg_client().await.recv().await?;
      let (sql, params) = SelectSqlBuilder::new(AF_COLLAB_SNAPSHOT_TABLE)
        .column(AF_COLLAB_SNAPSHOT_ID_COLUMN)
        .column(AF_COLLAB_SNAPSHOT_BLOB_COLUMN)
        .column(AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN)
        .order_by(AF_COLLAB_SNAPSHOT_ID_COLUMN, false)
        .limit(1)
        .where_clause(AF_COLLAB_SNAPSHOT_OID_COLUMN, object_id.to_string())
        .build();

      let stmt = client.prepare_cached(&sql).await?;
      let all_rows = client
        .query_raw(&stmt, params)
        .await?
        .try_collect::<Vec<_>>()
        .await?;

      let row = all_rows.first().ok_or(anyhow::anyhow!(
        "Get latest snapshot failed. No row returned"
      ))?;
      let snapshot_id = row.try_get::<_, i64>(AF_COLLAB_SNAPSHOT_ID_COLUMN)?;
      let update = row.try_get::<_, Vec<u8>>(AF_COLLAB_SNAPSHOT_BLOB_COLUMN)?;
      let created_at = row
        .try_get::<_, DateTime<Utc>>(AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN)?
        .timestamp();

      Ok(Some(RemoteCollabSnapshot {
        snapshot_id,
        oid: object_id.to_string(),
        data: update,
        created_at,
      }))
    },
  }
}

fn update_from_row(row: Row) -> Result<Vec<u8>, FlowyError> {
  row
    .try_get::<_, Vec<u8>>("value")
    .map_err(|e| FlowyError::internal().context(format!("Failed to get value from row: {}", e)))
}

#[allow(dead_code)]
fn decode_update_from_row(row: Row) -> Result<YrsUpdate, FlowyError> {
  let update = update_from_row(row)?;
  YrsUpdate::decode_v1(&update).map_err(|_| FlowyError::internal().context("Invalid yrs update"))
}

fn merge_update_from_rows(rows: Vec<Row>, new_update: Vec<u8>) -> Result<Vec<u8>, FlowyError> {
  let mut updates = vec![];
  for row in rows {
    let update = update_from_row(row)?;
    updates.push(update);
  }
  updates.push(new_update);

  let updates = updates
    .iter()
    .map(|update| update.as_ref())
    .collect::<Vec<&[u8]>>();

  merge_updates_v1(&updates).map_err(|_| FlowyError::internal().context("Failed to merge updates"))
}
