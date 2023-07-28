use std::future::Future;
use std::iter::Take;
use std::pin::Pin;
use std::str::FromStr;
use std::sync::{Arc, Weak};
use std::time::Duration;

use anyhow::Error;
use chrono::{DateTime, Utc};
use collab_plugins::cloud_storage::{CollabType, RemoteCollabSnapshot};
use serde_json::Value;
use tokio_retry::strategy::FixedInterval;
use tokio_retry::{Action, Retry};

use flowy_database_deps::cloud::{CollabObjectUpdate, CollabObjectUpdateByOid};
use lib_infra::util::md5;

use crate::supabase::storage_impls::pooler::{
  AF_COLLAB_KEY_COLUMN, AF_COLLAB_SNAPSHOT_BLOB_COLUMN, AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN,
  AF_COLLAB_SNAPSHOT_ID_COLUMN, AF_COLLAB_SNAPSHOT_OID_COLUMN, AF_COLLAB_SNAPSHOT_TABLE,
};
use crate::supabase::storage_impls::restful_api::util::ExtendedResponse;
use crate::supabase::storage_impls::restful_api::PostgresWrapper;
use crate::supabase::storage_impls::table_name;

pub struct FetchObjectUpdateAction {
  object_id: String,
  object_ty: CollabType,
  postgrest: Weak<PostgresWrapper>,
}

impl FetchObjectUpdateAction {
  pub fn new(object_id: String, object_ty: CollabType, postgrest: Weak<PostgresWrapper>) -> Self {
    Self {
      postgrest,
      object_id,
      object_ty,
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
    let weak_postgres = self.postgrest.clone();
    let object_id = self.object_id.clone();
    let object_ty = self.object_ty.clone();
    Box::pin(async move {
      match weak_postgres.upgrade() {
        None => Ok(vec![]),
        Some(postgrest) => {
          let items = get_updates_from_server(&object_id, &object_ty, postgrest).await?;
          Ok(items.into_iter().map(|item| item.value).collect())
        },
      }
    })
  }
}

pub struct BatchFetchObjectUpdateAction {
  object_ids: Vec<String>,
  object_ty: CollabType,
  postgrest: Weak<PostgresWrapper>,
}

impl BatchFetchObjectUpdateAction {
  pub fn new(
    object_ids: Vec<String>,
    object_ty: CollabType,
    postgrest: Weak<PostgresWrapper>,
  ) -> Self {
    Self {
      postgrest,
      object_ty,
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
    let weak_postgrest = self.postgrest.clone();
    let object_ids = self.object_ids.clone();
    let object_ty = self.object_ty.clone();
    Box::pin(async move {
      match weak_postgrest.upgrade() {
        None => Ok(CollabObjectUpdateByOid::default()),
        Some(server) => batch_get_updates_from_server(object_ids, &object_ty, server).await,
      }
    })
  }
}

pub async fn get_latest_snapshot_from_server(
  object_id: &str,
  postgrest: Arc<PostgresWrapper>,
) -> Result<Option<RemoteCollabSnapshot>, Error> {
  let json = postgrest
    .from(AF_COLLAB_SNAPSHOT_TABLE)
    .select(format!(
      "{},{},{}",
      AF_COLLAB_SNAPSHOT_ID_COLUMN,
      AF_COLLAB_SNAPSHOT_BLOB_COLUMN,
      AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN
    ))
    .order(format!("{}.desc", AF_COLLAB_SNAPSHOT_ID_COLUMN))
    .limit(1)
    .eq(AF_COLLAB_SNAPSHOT_OID_COLUMN, object_id)
    .execute()
    .await?
    .get_json()
    .await?;

  let snapshot = json
    .as_array()
    .and_then(|array| array.first())
    .and_then(|value| {
      let blob = value
        .get("blob")
        .and_then(|blob| blob.as_str())
        .and_then(decode_hex_string)?;
      let sid = value.get("sid").and_then(|id| id.as_i64())?;
      let created_at = value.get("created_at").and_then(|created_at| {
        created_at
          .as_str()
          .map(|id| DateTime::<Utc>::from_str(id).ok())
          .and_then(|date| date)
      })?;

      Some(RemoteCollabSnapshot {
        sid,
        oid: object_id.to_string(),
        blob,
        created_at: created_at.timestamp(),
      })
    });
  Ok(snapshot)
}

pub async fn batch_get_updates_from_server(
  object_ids: Vec<String>,
  object_ty: &CollabType,
  postgrest: Arc<PostgresWrapper>,
) -> Result<CollabObjectUpdateByOid, Error> {
  let json = postgrest
    .from(table_name(object_ty))
    .select("value, md5")
    .order(format!("{}.asc", AF_COLLAB_KEY_COLUMN))
    .in_("oid", object_ids)
    .execute()
    .await?
    .get_json()
    .await?;

  let updates_by_oid = CollabObjectUpdateByOid::new();
  if let Some(records) = json.as_array() {
    for record in records {
      tracing::debug!("record: {:?}", record);
    }
  }

  Ok(updates_by_oid)
}

pub async fn get_updates_from_server(
  object_id: &str,
  object_ty: &CollabType,
  postgrest: Arc<PostgresWrapper>,
) -> Result<Vec<UpdateItem>, Error> {
  let json = postgrest
    .from(table_name(object_ty))
    .select("key, value, md5")
    .order(format!("{}.asc", AF_COLLAB_KEY_COLUMN))
    .eq("oid", object_id)
    .execute()
    .await?
    .get_json()
    .await?;
  parser_updates_form_json(json)
}

/// json format:
/// ```json
/// [
///  {
///   "value": "\\x...",
///   "md5": "..."
///  },
///  {
///   "value": "\\x...",
///   "md5": "..."
///  },
/// ...
/// ]
/// ```
fn parser_updates_form_json(json: Value) -> Result<Vec<UpdateItem>, Error> {
  let mut updates = vec![];
  if let Some(records) = json.as_array() {
    for record in records {
      let some_record = record
        .get("value")
        .and_then(|value| value.as_str())
        .and_then(decode_hex_string);

      let some_key = record.get("key").and_then(|value| value.as_i64());
      if let (Some(value), Some(key)) = (some_record, some_key) {
        // Check the md5 of the value that we received from the server is equal to the md5 of the value
        // that we calculated locally.
        if let Some(expected_md5) = record.get("md5").and_then(|v| v.as_str()) {
          let value_md5 = md5(&value);
          debug_assert!(
            value_md5 == expected_md5,
            "md5 not match: {} != {}",
            value_md5,
            expected_md5
          );
        }
        updates.push(UpdateItem { key, value });
      } else {
        return Err(anyhow::anyhow!("value not found in json: {:?}", record));
      }
    }
  }
  Ok(updates)
}

pub struct UpdateItem {
  pub key: i64,
  pub value: Vec<u8>,
}

fn decode_hex_string(s: &str) -> Option<Vec<u8>> {
  let s = s.strip_prefix("\\x")?;
  hex::decode(s).ok()
}
