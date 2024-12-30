use std::future::Future;
use std::iter::Take;
use std::pin::Pin;
use std::str::FromStr;
use std::sync::{Arc, Weak};
use std::time::Duration;

use anyhow::Error;
use chrono::{DateTime, Utc};
use collab::core::collab::DataSource;
use collab_entity::{CollabObject, CollabType};
use collab_plugins::cloud_storage::RemoteCollabSnapshot;
use serde_json::Value;
use tokio_retry::strategy::FixedInterval;
use tokio_retry::{Action, Condition, RetryIf};
use yrs::merge_updates_v1;

use flowy_database_pub::cloud::CollabDocStateByOid;
use lib_infra::util::md5;

use crate::response::ExtendedResponse;
use crate::supabase::api::util::{
  BinaryColumnDecoder, InsertParamsBuilder, SupabaseBinaryColumnDecoder,
  SupabaseBinaryColumnEncoder,
};
use crate::supabase::api::PostgresWrapper;
use crate::supabase::define::*;

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

  pub fn run(self) -> RetryIf<Take<FixedInterval>, FetchObjectUpdateAction, RetryCondition> {
    let postgrest = self.postgrest.clone();
    let retry_strategy = FixedInterval::new(Duration::from_secs(5)).take(3);
    RetryIf::spawn(retry_strategy, self, RetryCondition(postgrest))
  }

  pub fn run_with_fix_interval(
    self,
    secs: u64,
    times: usize,
  ) -> RetryIf<Take<FixedInterval>, FetchObjectUpdateAction, RetryCondition> {
    let postgrest = self.postgrest.clone();
    let retry_strategy = FixedInterval::new(Duration::from_secs(secs)).take(times);
    RetryIf::spawn(retry_strategy, self, RetryCondition(postgrest))
  }
}

impl Action for FetchObjectUpdateAction {
  type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send>>;
  type Item = Vec<u8>;
  type Error = anyhow::Error;

  fn run(&mut self) -> Self::Future {
    let weak_postgres = self.postgrest.clone();
    let object_id = self.object_id.clone();
    let object_ty = self.object_ty.clone();
    Box::pin(async move {
      match weak_postgres.upgrade() {
        None => Ok(vec![]),
        Some(postgrest) => {
          match get_updates_from_server(&object_id, &object_ty, &postgrest).await {
            Ok(items) => {
              if items.is_empty() {
                return Ok(vec![]);
              }

              let updates = items.into_iter().map(|update| update.value);
              let doc_state = merge_updates_v1(updates)
                .map_err(|err| anyhow::anyhow!("merge updates failed: {:?}", err))?;
              Ok(doc_state)
            },
            Err(err) => {
              tracing::error!("Get {} updates failed with error: {:?}", object_id, err);
              Err(err)
            },
          }
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

  pub fn run(self) -> RetryIf<Take<FixedInterval>, BatchFetchObjectUpdateAction, RetryCondition> {
    let postgrest = self.postgrest.clone();
    let retry_strategy = FixedInterval::new(Duration::from_secs(5)).take(3);
    RetryIf::spawn(retry_strategy, self, RetryCondition(postgrest))
  }
}

impl Action for BatchFetchObjectUpdateAction {
  type Future = Pin<Box<dyn Future<Output = Result<Self::Item, Self::Error>> + Send>>;
  type Item = CollabDocStateByOid;
  type Error = anyhow::Error;

  fn run(&mut self) -> Self::Future {
    let weak_postgrest = self.postgrest.clone();
    let object_ids = self.object_ids.clone();
    let object_ty = self.object_ty.clone();
    Box::pin(async move {
      match weak_postgrest.upgrade() {
        None => Ok(CollabDocStateByOid::default()),
        Some(server) => {
          match batch_get_updates_from_server(object_ids.clone(), &object_ty, server).await {
            Ok(updates_by_oid) => Ok(updates_by_oid),
            Err(err) => {
              tracing::error!(
                "Batch get object with given ids:{:?} failed with error: {:?}",
                object_ids,
                err
              );
              Err(err)
            },
          }
        },
      }
    })
  }
}

pub async fn create_snapshot(
  postgrest: &Arc<PostgresWrapper>,
  object: &CollabObject,
  snapshot: Vec<u8>,
) -> Result<i64, Error> {
  let value_size = snapshot.len() as i32;
  let (snapshot, encrypt) = SupabaseBinaryColumnEncoder::encode(&snapshot, &postgrest.secret())?;
  let ret: Value = postgrest
    .from(AF_COLLAB_SNAPSHOT_TABLE)
    .insert(
      InsertParamsBuilder::new()
        .insert(AF_COLLAB_SNAPSHOT_OID_COLUMN, object.object_id.clone())
        .insert("name", object.collab_type.to_string())
        .insert(AF_COLLAB_SNAPSHOT_ENCRYPT_COLUMN, encrypt)
        .insert(AF_COLLAB_SNAPSHOT_BLOB_COLUMN, snapshot)
        .insert(AF_COLLAB_SNAPSHOT_BLOB_SIZE_COLUMN, value_size)
        .build(),
    )
    .execute()
    .await?
    .get_json()
    .await?;

  let snapshot_id = ret
    .as_array()
    .and_then(|array| array.first())
    .and_then(|value| value.get("sid"))
    .and_then(|value| value.as_i64())
    .unwrap_or(0);
  Ok(snapshot_id)
}

pub async fn get_snapshots_from_server(
  object_id: &str,
  postgrest: Arc<PostgresWrapper>,
  limit: usize,
) -> Result<Vec<RemoteCollabSnapshot>, Error> {
  let json: Value = postgrest
    .from(AF_COLLAB_SNAPSHOT_TABLE)
    .select(format!(
      "{},{},{},{}",
      AF_COLLAB_SNAPSHOT_ID_COLUMN,
      AF_COLLAB_SNAPSHOT_BLOB_COLUMN,
      AF_COLLAB_SNAPSHOT_CREATED_AT_COLUMN,
      AF_COLLAB_SNAPSHOT_ENCRYPT_COLUMN
    ))
    .order(format!("{}.desc", AF_COLLAB_SNAPSHOT_ID_COLUMN))
    .limit(limit)
    .eq(AF_COLLAB_SNAPSHOT_OID_COLUMN, object_id)
    .execute()
    .await?
    .get_json()
    .await?;

  let mut snapshots = vec![];
  let secret = postgrest.secret();
  match json.as_array() {
    None => {
      if let Some(snapshot) = parser_snapshot(object_id, &json, &secret) {
        snapshots.push(snapshot);
      }
    },
    Some(snapshot_values) => {
      for snapshot_value in snapshot_values {
        if let Some(snapshot) = parser_snapshot(object_id, snapshot_value, &secret) {
          snapshots.push(snapshot);
        }
      }
    },
  }
  Ok(snapshots)
}

fn parser_snapshot(
  object_id: &str,
  snapshot: &Value,
  secret: &Option<String>,
) -> Option<RemoteCollabSnapshot> {
  let blob = match (
    snapshot
      .get(AF_COLLAB_SNAPSHOT_ENCRYPT_COLUMN)
      .and_then(|encrypt| encrypt.as_i64()),
    snapshot
      .get(AF_COLLAB_SNAPSHOT_BLOB_COLUMN)
      .and_then(|value| value.as_str()),
  ) {
    (Some(encrypt), Some(value)) => {
      SupabaseBinaryColumnDecoder::decode::<_, BinaryColumnDecoder>(value, encrypt as i32, secret)
        .ok()
    },
    _ => None,
  }?;

  let sid = snapshot.get("sid").and_then(|id| id.as_i64())?;
  let created_at = snapshot.get("created_at").and_then(|created_at| {
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
}

pub async fn batch_get_updates_from_server(
  object_ids: Vec<String>,
  object_ty: &CollabType,
  postgrest: Arc<PostgresWrapper>,
) -> Result<CollabDocStateByOid, Error> {
  let json = postgrest
    .from(table_name(object_ty))
    .select("oid, key, value, encrypt, md5")
    .order(format!("{}.asc", AF_COLLAB_KEY_COLUMN))
    .in_("oid", object_ids)
    .execute()
    .await?
    .get_json()
    .await?;

  let mut updates_by_oid = CollabDocStateByOid::new();
  if let Some(records) = json.as_array() {
    for record in records {
      tracing::debug!("get updates from server: {:?}", record);
      if let Some(oid) = record.get("oid").and_then(|value| value.as_str()) {
        match parser_updates_form_json(record.clone(), &postgrest.secret()) {
          Ok(items) => {
            if items.is_empty() {
              updates_by_oid.insert(oid.to_string(), DataSource::Disk);
            } else {
              let updates = items.into_iter().map(|update| update.value);

              let doc_state = merge_updates_v1(updates)
                .map_err(|err| anyhow::anyhow!("merge updates failed: {:?}", err))?;
              updates_by_oid.insert(oid.to_string(), DataSource::DocStateV1(doc_state));
            }
          },
          Err(e) => {
            tracing::error!("parser_updates_form_json error: {:?}", e);
          },
        }
      }
    }
  }
  Ok(updates_by_oid)
}

pub async fn get_updates_from_server(
  object_id: &str,
  object_ty: &CollabType,
  postgrest: &Arc<PostgresWrapper>,
) -> Result<Vec<UpdateItem>, Error> {
  let json = postgrest
    .from(table_name(object_ty))
    .select("key, value, encrypt, md5")
    .order(format!("{}.asc", AF_COLLAB_KEY_COLUMN))
    .eq("oid", object_id)
    .execute()
    .await?
    .get_json()
    .await?;
  parser_updates_form_json(json, &postgrest.secret())
}

/// json format:
/// ```json
/// [
///  {
///   "value": "\\x...",
///   "encrypt": 1,
///   "md5": "..."
///  },
///  {
///   "value": "\\x...",
///   "encrypt": 1,
///   "md5": "..."
///  },
/// ...
/// ]
/// ```
fn parser_updates_form_json(
  json: Value,
  encryption_secret: &Option<String>,
) -> Result<Vec<UpdateItem>, Error> {
  let mut updates = vec![];
  match json.as_array() {
    None => {
      updates.push(parser_update_from_json(&json, encryption_secret)?);
    },
    Some(values) => {
      let expected_update_len = values.len();
      for value in values {
        updates.push(parser_update_from_json(value, encryption_secret)?);
      }
      if updates.len() != expected_update_len {
        return Err(anyhow::anyhow!(
          "The length of the updates does not match the length of the expected updates, indicating that some updates failed to parse."
        ));
      }
    },
  }

  Ok(updates)
}

/// Parses update from a JSON representation.
///
/// This function attempts to decode an encrypted value from a JSON object
/// and verify its integrity against a provided MD5 hash.
///
/// # Parameters
/// - `json`: The JSON value representing the update information.
/// - `encryption_secret`: An optional encryption secret used for decrypting the value.
///
/// json format:
/// ```json
///  {
///   "value": "\\x...",
///   "encrypt": 1,
///   "md5": "..."
///  },
/// ```
fn parser_update_from_json(
  json: &Value,
  encryption_secret: &Option<String>,
) -> Result<UpdateItem, Error> {
  let some_record = match (
    json.get("encrypt").and_then(|encrypt| encrypt.as_i64()),
    json.get("value").and_then(|value| value.as_str()),
  ) {
    (Some(encrypt), Some(value)) => {
      match SupabaseBinaryColumnDecoder::decode::<_, BinaryColumnDecoder>(
        value,
        encrypt as i32,
        encryption_secret,
      ) {
        Ok(value) => Some(value),
        Err(err) => {
          tracing::error!("Decode value column failed: {:?}", err);
          None
        },
      }
    },
    _ => None,
  };

  let some_key = json.get("key").and_then(|value| value.as_i64());
  if let (Some(value), Some(key)) = (some_record, some_key) {
    // Check the md5 of the value that we received from the server is equal to the md5 of the value
    // that we calculated locally.
    if let Some(expected_md5) = json.get("md5").and_then(|v| v.as_str()) {
      let value_md5 = md5(&value);
      if value_md5 != expected_md5 {
        let msg = format!(
          "md5 not match: key:{} {} != {}",
          key, value_md5, expected_md5
        );
        tracing::error!("{}", msg);
        return Err(anyhow::anyhow!(msg));
      }
    }
    Ok(UpdateItem { key, value })
  } else {
    let keys = json
      .as_object()
      .map(|map| map.iter().map(|(key, _)| key).collect::<Vec<&String>>());
    Err(anyhow::anyhow!(
      "missing key or value column. Current keys:: {:?}",
      keys
    ))
  }
}

pub struct UpdateItem {
  pub key: i64,
  pub value: Vec<u8>,
}

pub struct RetryCondition(pub Weak<PostgresWrapper>);
impl Condition<anyhow::Error> for RetryCondition {
  fn should_retry(&mut self, _error: &anyhow::Error) -> bool {
    self.0.upgrade().is_some()
  }
}
