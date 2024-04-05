use std::str::FromStr;
use std::sync::{Arc, Weak};

use anyhow::Error;
use chrono::{DateTime, Utc};
use client_api::collab_sync::MsgId;
use collab::core::collab::DocStateSource;
use collab::preclude::merge_updates_v1;
use collab_entity::CollabObject;
use collab_plugins::cloud_storage::{
  RemoteCollabSnapshot, RemoteCollabState, RemoteCollabStorage, RemoteUpdateReceiver,
};
use parking_lot::Mutex;
use tokio::task::spawn_blocking;

use lib_infra::async_trait::async_trait;
use lib_infra::util::md5;

use crate::response::ExtendedResponse;
use crate::supabase::api::request::{
  create_snapshot, get_snapshots_from_server, get_updates_from_server, FetchObjectUpdateAction,
  UpdateItem,
};
use crate::supabase::api::util::{InsertParamsBuilder, SupabaseBinaryColumnEncoder};
use crate::supabase::api::{PostgresWrapper, SupabaseServerService};
use crate::supabase::define::*;
use crate::AppFlowyEncryption;

pub struct SupabaseCollabStorageImpl<T> {
  server: T,
  rx: Mutex<Option<RemoteUpdateReceiver>>,
  encryption: Weak<dyn AppFlowyEncryption>,
}

impl<T> SupabaseCollabStorageImpl<T> {
  pub fn new(
    server: T,
    rx: Option<RemoteUpdateReceiver>,
    encryption: Weak<dyn AppFlowyEncryption>,
  ) -> Self {
    Self {
      server,
      rx: Mutex::new(rx),
      encryption,
    }
  }

  pub fn secret(&self) -> Option<String> {
    match self.encryption.upgrade() {
      None => None,
      Some(encryption) => encryption.get_secret(),
    }
  }
}

#[async_trait]
impl<T> RemoteCollabStorage for SupabaseCollabStorageImpl<T>
where
  T: SupabaseServerService,
{
  fn is_enable(&self) -> bool {
    true
  }

  async fn get_doc_state(&self, object: &CollabObject) -> Result<DocStateSource, Error> {
    let postgrest = self.server.try_get_weak_postgrest()?;
    let action = FetchObjectUpdateAction::new(
      object.object_id.clone(),
      object.collab_type.clone(),
      postgrest,
    );
    let doc_state = action.run().await?;
    Ok(DocStateSource::FromDocState(doc_state))
  }

  async fn get_snapshots(&self, object_id: &str, limit: usize) -> Vec<RemoteCollabSnapshot> {
    match self.server.try_get_postgrest() {
      Ok(postgrest) => get_snapshots_from_server(object_id, postgrest, limit)
        .await
        .unwrap_or_else(|err| {
          tracing::error!(
            "🔴fetch snapshots by oid:{} with limit: {} failed: {:?}",
            object_id,
            limit,
            err
          );
          vec![]
        }),
      Err(err) => {
        tracing::error!("🔴get postgrest failed: {:?}", err);
        vec![]
      },
    }
  }

  async fn get_collab_state(&self, object_id: &str) -> Result<Option<RemoteCollabState>, Error> {
    let postgrest = self.server.try_get_postgrest()?;
    let json = postgrest
      .from("af_collab_state")
      .select("*")
      .eq("oid", object_id)
      .order("snapshot_created_at.desc".to_string())
      .limit(1)
      .execute()
      .await?
      .get_json()
      .await?;

    Ok(
      json
        .as_array()
        .and_then(|array| array.first())
        .and_then(|value| {
          let created_at = value.get("snapshot_created_at").and_then(|created_at| {
            created_at
              .as_str()
              .map(|id| DateTime::<Utc>::from_str(id).ok())
              .and_then(|date| date)
          })?;

          let current_edit_count = value.get("current_edit_count").and_then(|id| id.as_i64())?;
          let snapshot_edit_count = value
            .get("snapshot_edit_count")
            .and_then(|id| id.as_i64())?;

          Some(RemoteCollabState {
            current_edit_count,
            snapshot_edit_count,
            snapshot_created_at: created_at.timestamp(),
          })
        }),
    )
  }

  async fn create_snapshot(&self, object: &CollabObject, snapshot: Vec<u8>) -> Result<i64, Error> {
    let postgrest = self.server.try_get_postgrest()?;
    create_snapshot(&postgrest, object, snapshot).await
  }

  async fn send_update(
    &self,
    object: &CollabObject,
    _id: MsgId,
    update: Vec<u8>,
  ) -> Result<(), Error> {
    if let Some(postgrest) = self.server.get_postgrest() {
      send_update(
        object.workspace_id.clone(),
        object,
        update,
        &postgrest,
        &self.secret(),
      )
      .await?;
    }

    Ok(())
  }

  async fn send_init_sync(
    &self,
    object: &CollabObject,
    _id: MsgId,
    init_update: Vec<u8>,
  ) -> Result<(), Error> {
    let postgrest = self.server.try_get_postgrest()?;

    let update_items =
      get_updates_from_server(&object.object_id, &object.collab_type, &postgrest).await?;

    // If the update_items is empty, we can send the init_update directly
    if update_items.is_empty() {
      send_update(
        object.workspace_id.clone(),
        object,
        init_update,
        &postgrest,
        &self.secret(),
      )
      .await?;
    } else {
      flush_collab_with_update(object, update_items, &postgrest, init_update, self.secret())
        .await?;
    }
    Ok(())
  }

  fn subscribe_remote_updates(&self, _object: &CollabObject) -> Option<RemoteUpdateReceiver> {
    let rx = self.rx.lock().take();
    if rx.is_none() {
      tracing::warn!("The receiver is already taken");
    }
    rx
  }
}

pub(crate) async fn flush_collab_with_update(
  object: &CollabObject,
  update_items: Vec<UpdateItem>,
  postgrest: &Arc<PostgresWrapper>,
  update: Vec<u8>,
  secret: Option<String>,
) -> Result<(), Error> {
  // 2.Merge the updates into one and then delete the merged updates
  let merge_result = spawn_blocking(move || merge_updates(update_items, update)).await??;
  let value_size = merge_result.new_update.len() as i32;
  let md5 = md5(&merge_result.new_update);

  tracing::trace!(
    "Flush collab id:{} type:{} is_encrypt: {}",
    object.object_id,
    object.collab_type,
    secret.is_some()
  );
  let (new_update, encrypt) =
    SupabaseBinaryColumnEncoder::encode(merge_result.new_update, &secret)?;
  let params = InsertParamsBuilder::new()
    .insert("oid", object.object_id.clone())
    .insert("new_value", new_update)
    .insert("encrypt", encrypt)
    .insert("md5", md5)
    .insert("value_size", value_size)
    .insert("partition_key", partition_key(&object.collab_type))
    .insert("uid", object.uid)
    .insert("workspace_id", &object.workspace_id)
    .insert("removed_keys", merge_result.merged_keys)
    .insert("did", &object.device_id)
    .build();

  postgrest
    .rpc("flush_collab_updates_v3", params)
    .execute()
    .await?
    .success()
    .await?;
  Ok(())
}

pub(crate) async fn send_update(
  workspace_id: String,
  object: &CollabObject,
  update: Vec<u8>,
  postgrest: &Arc<PostgresWrapper>,
  encryption_secret: &Option<String>,
) -> Result<(), Error> {
  let value_size = update.len() as i32;
  let md5 = md5(&update);
  let (update, encrypt) = SupabaseBinaryColumnEncoder::encode(update, encryption_secret)?;
  let builder = InsertParamsBuilder::new()
    .insert("oid", object.object_id.clone())
    .insert("partition_key", partition_key(&object.collab_type))
    .insert("value", update)
    .insert("encrypt", encrypt)
    .insert("uid", object.uid)
    .insert("md5", md5)
    .insert("workspace_id", workspace_id)
    .insert("did", &object.device_id)
    .insert("value_size", value_size);

  let params = builder.build();
  postgrest
    .from(AF_COLLAB_UPDATE_TABLE)
    .insert(params)
    .execute()
    .await?
    .success()
    .await?;
  Ok(())
}

fn merge_updates(update_items: Vec<UpdateItem>, new_update: Vec<u8>) -> Result<MergeResult, Error> {
  let mut updates = vec![];
  let mut merged_keys = vec![];
  for item in update_items {
    merged_keys.push(item.key);
    updates.push(item.value);
  }
  if !new_update.is_empty() {
    updates.push(new_update);
  }
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
