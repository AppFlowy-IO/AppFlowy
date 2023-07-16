use std::future::Future;
use std::iter::Take;
use std::pin::Pin;
use std::sync::Weak;
use std::time::Duration;

use anyhow::Error;
use appflowy_integrate::{
  merge_updates_v1, CollabObject, MsgId, RemoteCollabSnapshot, RemoteCollabState,
  RemoteCollabStorage, RemoteUpdateReceiver,
};
use chrono::{DateTime, Utc};
use deadpool_postgres::GenericClient;
use futures::pin_mut;
use futures_util::{StreamExt, TryStreamExt};
use tokio::task::spawn_blocking;
use tokio_postgres::types::ToSql;
use tokio_postgres::Row;
use tokio_retry::strategy::FixedInterval;
use tokio_retry::{Action, Retry};

use flowy_database2::deps::{CollabObjectUpdate, CollabObjectUpdateByOid};
use lib_infra::async_trait::async_trait;
use lib_infra::util::md5;

use crate::supabase::postgres_db::PostgresObject;
use crate::supabase::sql_builder::{
  DeleteSqlBuilder, InsertSqlBuilder, SelectSqlBuilder, WhereCondition,
};
use crate::supabase::{PostgresServer, SupabaseServerService};

pub struct PgCollabStorageImpl<T> {
  server: T,
}

const AF_COLLAB_KEY_COLUMN: &str = "key";
const AF_COLLAB_SNAPSHOT_OID_COLUMN: &str = "oid";
const AF_COLLAB_SNAPSHOT_ID_COLUMN: &str = "sid";
const AF_COLLAB_SNAPSHOT_BLOB_COLUMN: &str = "blob";
const AF_COLLAB_SNAPSHOT_BLOB_SIZE_COLUMN: &str = "blob_size";
const AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN: &str = "created_at";
const AF_COLLAB_SNAPSHOT_TABLE: &str = "af_collab_snapshot";

impl<T> PgCollabStorageImpl<T>
where
  T: SupabaseServerService,
{
  pub fn new(server: T) -> Self {
    Self { server }
  }

  pub async fn get_client(&self) -> Option<PostgresObject> {
    self
      .server
      .get_pg_server()?
      .upgrade()?
      .get_pg_client()
      .await
      .recv()
      .await
      .ok()
  }
}

#[async_trait]
impl<T> RemoteCollabStorage for PgCollabStorageImpl<T>
where
  T: SupabaseServerService,
{
  fn is_enable(&self) -> bool {
    self
      .server
      .get_pg_server()
      .and_then(|server| server.upgrade())
      .is_some()
  }

  async fn get_all_updates(&self, object_id: &str) -> Result<Vec<Vec<u8>>, Error> {
    let pg_server = self.server.try_get_pg_server()?;
    let action = FetchObjectUpdateAction::new(object_id, pg_server);
    let updates = action.run().await?;
    Ok(updates)
  }

  async fn get_latest_snapshot(
    &self,
    object_id: &str,
  ) -> Result<Option<RemoteCollabSnapshot>, Error> {
    match self.server.get_pg_server() {
      None => Ok(None),
      Some(weak_server) => get_latest_snapshot_from_server(object_id, weak_server).await,
    }
  }

  async fn get_collab_state(&self, object_id: &str) -> Result<Option<RemoteCollabState>, Error> {
    let client = self.get_client().await;
    if client.is_none() {
      return Ok(None);
    }

    let client = client.unwrap();
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
    let client = self
      .get_client()
      .await
      .ok_or_else(|| anyhow::anyhow!("Create snapshot failed. No client available"))?;
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
    if let Some(client) = self.get_client().await {
      let value_size = update.len() as i32;
      let md5 = md5(&update);
      let (sql, params) = InsertSqlBuilder::new("af_collab")
        .value("oid", object.id.clone())
        .value("name", object.name.clone())
        .value("value", update)
        .value("uid", object.uid)
        .value("md5", md5)
        .value("value_size", value_size)
        .build();

      let stmt = client.prepare_cached(&sql).await?;
      client.execute_raw(&stmt, params).await?;
    }
    Ok(())
  }

  async fn send_init_sync(
    &self,
    object: &CollabObject,
    _id: MsgId,
    init_update: Vec<u8>,
  ) -> Result<(), Error> {
    let client = self.get_client().await;
    if client.is_none() {
      return Ok(());
    }

    let mut client = client.unwrap();
    let txn = client.transaction().await?;

    // 1.Get all updates and lock the table. It means that a subsequent UPDATE, DELETE, or SELECT
    // FOR UPDATE by this transaction will not result in a lock wait. other transactions that try
    // to update or lock these specific rows will be blocked until the current transaction ends
    let (sql, params) = SelectSqlBuilder::new("af_collab")
      .column(AF_COLLAB_KEY_COLUMN)
      .column("value")
      .order_by(AF_COLLAB_KEY_COLUMN, true)
      .where_clause("oid", object.id.clone())
      .lock()
      .build();

    let get_all_update_stmt = txn.prepare_cached(&sql).await?;
    let row_stream = txn.query_raw(&get_all_update_stmt, params).await?;
    let pg_rows = row_stream.try_collect::<Vec<_>>().await?;

    let insert_builder = InsertSqlBuilder::new("af_collab")
      .value("oid", object.id.clone())
      .value("uid", object.uid)
      .value("name", object.name.clone());

    let (sql, params) = if !pg_rows.is_empty() {
      let last_row_key = pg_rows
        .last()
        .map(|row| row.get::<_, i64>(AF_COLLAB_KEY_COLUMN))
        .unwrap();

      // 2.Merge the updates into one and then delete the merged updates
      let merge_result =
        spawn_blocking(move || merge_update_from_rows(pg_rows, init_update)).await??;
      tracing::trace!("Merged updates count: {}", merge_result.merged_keys.len());

      // 3. Delete merged updates
      let (sql, params) = DeleteSqlBuilder::new("af_collab")
        .where_condition(WhereCondition::Equals(
          "oid".to_string(),
          Box::new(object.id.clone()),
        ))
        .where_condition(WhereCondition::In(
          AF_COLLAB_KEY_COLUMN.to_string(),
          merge_result
            .merged_keys
            .into_iter()
            .map(|key| Box::new(key) as Box<dyn ToSql + Send + Sync>)
            .collect::<Vec<_>>(),
        ))
        .build();
      let delete_stmt = txn.prepare_cached(&sql).await?;
      txn.execute_raw(&delete_stmt, params).await?;

      // 4. Insert the merged update. The new_update contains the merged update and the
      // init_update.
      let new_update = merge_result.new_update;

      let value_size = new_update.len() as i32;
      let md5 = md5(&new_update);
      insert_builder
        .value("value", new_update)
        .value("value_size", value_size)
        .value("md5", md5)
        .value(AF_COLLAB_KEY_COLUMN, last_row_key)
        .overriding_system_value()
        .build()
    } else {
      let value_size = init_update.len() as i32;
      let md5 = md5(&init_update);
      insert_builder
        .value("value", init_update)
        .value("md5", md5)
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

  async fn subscribe_remote_updates(&self, _object: &CollabObject) -> Option<RemoteUpdateReceiver> {
    // using pg_notify to subscribe to updates
    None
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
          .flat_map(|row| update_from_row(&row).ok())
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

fn update_from_row(row: &Row) -> Result<Vec<u8>, anyhow::Error> {
  let update = row.try_get::<_, Vec<u8>>("value")?;
  Ok(update)
}

fn merge_update_from_rows(
  rows: Vec<Row>,
  new_update: Vec<u8>,
) -> Result<MergeResult, anyhow::Error> {
  let mut updates = vec![];
  let mut merged_keys = vec![];
  for row in rows {
    merged_keys.push(row.try_get::<_, i64>(AF_COLLAB_KEY_COLUMN)?);
    let update = update_from_row(&row)?;
    updates.push(update);
  }
  updates.push(new_update);
  let updates = updates
    .iter()
    .map(|update| update.as_ref())
    .collect::<Vec<&[u8]>>();

  let new_update = merge_updates_v1(&updates)?;
  Ok(MergeResult {
    merged_keys,
    new_update,
  })
}

struct MergeResult {
  merged_keys: Vec<i64>,
  new_update: Vec<u8>,
}

pub struct FetchObjectUpdateAction {
  object_id: String,
  pg_server: Weak<PostgresServer>,
}

impl FetchObjectUpdateAction {
  pub fn new(object_id: &str, pg_server: Weak<PostgresServer>) -> Self {
    Self {
      pg_server,
      object_id: object_id.to_string(),
    }
  }

  pub fn run(self) -> Retry<Take<FixedInterval>, FetchObjectUpdateAction> {
    let retry_strategy = FixedInterval::new(Duration::from_secs(5)).take(3);
    Retry::spawn(retry_strategy, self)
  }

  pub fn run_with_fix_interval(
    self,
    secs: u64,
    times: usize,
  ) -> Retry<Take<FixedInterval>, FetchObjectUpdateAction> {
    let retry_strategy = FixedInterval::new(Duration::from_secs(secs)).take(times);
    Retry::spawn(retry_strategy, self)
  }
}

impl Action for FetchObjectUpdateAction {
  type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send>>;
  type Item = CollabObjectUpdate;
  type Error = anyhow::Error;

  fn run(&mut self) -> Self::Future {
    let weak_pb_server = self.pg_server.clone();
    let object_id = self.object_id.clone();
    Box::pin(async move {
      match weak_pb_server.upgrade() {
        None => Ok(vec![]),
        Some(server) => {
          let client = server.get_pg_client().await.recv().await?;
          let (sql, params) = SelectSqlBuilder::new("af_collab")
            .column("value")
            .order_by(AF_COLLAB_KEY_COLUMN, true)
            .where_clause("oid", object_id)
            .build();
          let stmt = client.prepare_cached(&sql).await?;
          let row_stream = client.query_raw(&stmt, params).await?;
          Ok(
            row_stream
              .try_collect::<Vec<_>>()
              .await?
              .into_iter()
              .flat_map(|row| update_from_row(&row).ok())
              .collect(),
          )
        },
      }
    })
  }
}

pub struct BatchFetchObjectUpdateAction {
  object_ids: Vec<String>,
  pg_server: Weak<PostgresServer>,
}

impl BatchFetchObjectUpdateAction {
  pub fn new(object_ids: Vec<String>, pg_server: Weak<PostgresServer>) -> Self {
    Self {
      pg_server,
      object_ids,
    }
  }

  pub fn run(self) -> Retry<Take<FixedInterval>, BatchFetchObjectUpdateAction> {
    let retry_strategy = FixedInterval::new(Duration::from_secs(5)).take(3);
    Retry::spawn(retry_strategy, self)
  }
}

impl Action for BatchFetchObjectUpdateAction {
  type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send>>;
  type Item = CollabObjectUpdateByOid;
  type Error = anyhow::Error;

  fn run(&mut self) -> Self::Future {
    let weak_pb_server = self.pg_server.clone();
    let object_ids = self.object_ids.clone();
    Box::pin(async move {
      match weak_pb_server.upgrade() {
        None => Ok(CollabObjectUpdateByOid::default()),
        Some(server) => {
          let client = server.get_pg_client().await.recv().await?;
          let mut updates_by_oid = CollabObjectUpdateByOid::new();

          // Group the updates by oid
          let (sql, params) = SelectSqlBuilder::new("af_collab")
            .column("oid")
            .array_agg("value")
            .group_by("oid")
            .where_clause_in("oid", object_ids)
            .build();
          let stmt = client.prepare_cached(&sql).await?;

          // Poll the rows
          let rows = Box::pin(client.query_raw(&stmt, params).await?);
          pin_mut!(rows);
          while let Some(Ok(row)) = rows.next().await {
            let oid = row.try_get::<_, String>("oid")?;
            let updates = row.try_get::<_, Vec<Vec<u8>>>("value")?;
            updates_by_oid.insert(oid, updates);
          }
          Ok(updates_by_oid)
        },
      }
    })
  }
}
