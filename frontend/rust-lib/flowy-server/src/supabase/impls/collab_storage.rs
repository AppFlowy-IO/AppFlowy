use std::sync::Arc;

use anyhow::Error;
use appflowy_integrate::{
  merge_updates_v1, CollabObject, Decode, MsgId, RemoteCollabStorage, YrsUpdate,
};
use deadpool_postgres::GenericClient;
use futures::pin_mut;
use futures::StreamExt;
use futures_util::TryStreamExt;
use tokio::task::spawn_blocking;
use tokio_postgres::Row;

use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;

use crate::supabase::sql_builder::{InsertSqlBuilder, SelectSqlBuilder};
use crate::supabase::PostgresServer;

pub struct CollabStorageImpl {
  server: Arc<PostgresServer>,
}

impl CollabStorageImpl {
  pub fn new(server: Arc<PostgresServer>) -> Self {
    Self { server }
  }
}

#[async_trait]
impl RemoteCollabStorage for CollabStorageImpl {
  async fn get_all_updates(&self, object_id: &str) -> Result<Vec<Vec<u8>>, Error> {
    let client = self.server.get_pg_client().await.recv().await?;
    let stmt = client
      .prepare_cached("SELECT value FROM af_collab WHERE oid = $1 ORDER BY oid ASC")
      .await?;
    Ok(client.query(&stmt, &[&object_id]).await.map(|rows| {
      rows
        .into_iter()
        .flat_map(|row| update_from_row(row).ok())
        .collect()
    })?)
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
    id: MsgId,
    init_update: Vec<u8>,
  ) -> Result<(), Error> {
    let mut client = self.server.get_pg_client().await.recv().await?;
    let txn = client.transaction().await?;
    let (sql, params) = SelectSqlBuilder::new("af_collab")
      .column("value")
      .where_clause("oid", object.id.clone())
      .build();

    // 1.Get all updates
    let get_all_update_stmt = txn.prepare_cached(&sql).await?;

    let row_stream = txn.query_raw(&get_all_update_stmt, params).await?;
    let remote_updates = row_stream.try_collect::<Vec<_>>().await?;

    // 2.Delete all updates and insert the merged update
    let merged_update =
      spawn_blocking(move || merge_update_from_rows(remote_updates, init_update)).await??;
    let delete_stmt = txn
      .prepare_cached("DELETE FROM af_collab WHERE oid = $1")
      .await?;
    txn.execute(&delete_stmt, &[&object.id]).await?;

    // 3.Insert the merged update
    let insert_stmt = txn
      .prepare_cached("INSERT INTO af_collab (oid, name, value) VALUES ($1, $2, $3)")
      .await?;

    let value_size = merged_update.len() as i32;
    let (sql, params) = InsertSqlBuilder::new("af_collab")
      .value("oid", object.id.clone())
      .value("name", object.name.clone())
      .value("value", merged_update)
      .value("value_size", value_size)
      .build();
    let stmt = txn.prepare_cached(&sql).await?;
    txn.execute_raw(&stmt, params).await?;

    // commit the transaction
    txn.commit().await?;

    Ok(())
  }
}

fn update_from_row(row: Row) -> Result<Vec<u8>, FlowyError> {
  row
    .try_get::<_, Vec<u8>>("value")
    .map_err(|e| FlowyError::internal().context(format!("Failed to get value from row: {}", e)))
}

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
