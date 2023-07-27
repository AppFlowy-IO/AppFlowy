use crate::supabase::storage_impls::restful_api::request::{
  get_latest_snapshot_from_server, FetchObjectUpdateAction,
};
use crate::supabase::storage_impls::restful_api::util::{ExtendedResponse, InsertParamsBuilder};
use crate::supabase::storage_impls::restful_api::PostgresWrapper;
use crate::supabase::storage_impls::{partition_key, table_name};
use anyhow::Error;
use chrono::{DateTime, Utc};
use collab_plugins::cloud_storage::{
  CollabObject, MsgId, RemoteCollabSnapshot, RemoteCollabState, RemoteCollabStorage,
  RemoteUpdateReceiver,
};
use lib_infra::async_trait::async_trait;
use lib_infra::util::md5;

use std::str::FromStr;
use std::sync::Arc;

pub struct RESTfulSupabaseCollabStorageImpl {
  postgrest: Arc<PostgresWrapper>,
}

impl RESTfulSupabaseCollabStorageImpl {
  pub fn new(postgrest: Arc<PostgresWrapper>) -> Self {
    Self { postgrest }
  }
}

#[async_trait]
impl RemoteCollabStorage for RESTfulSupabaseCollabStorageImpl {
  fn is_enable(&self) -> bool {
    true
  }

  async fn get_all_updates(&self, object: &CollabObject) -> Result<Vec<Vec<u8>>, Error> {
    let action = FetchObjectUpdateAction::new(
      object.id.clone(),
      object.ty.clone(),
      Arc::downgrade(&self.postgrest),
    );
    let updates = action.run().await?;
    Ok(updates)
  }

  async fn get_latest_snapshot(&self, object_id: &str) -> Option<RemoteCollabSnapshot> {
    get_latest_snapshot_from_server(object_id, self.postgrest.clone())
      .await
      .ok()?
  }

  async fn get_collab_state(&self, object_id: &str) -> Result<Option<RemoteCollabState>, Error> {
    let json = self
      .postgrest
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
          let last_snapshot_edit_count = value
            .get("last_snapshot_edit_count")
            .and_then(|id| id.as_i64())?;

          Some(RemoteCollabState {
            current_edit_count,
            last_snapshot_edit_count,
            last_snapshot_created_at: created_at.timestamp(),
          })
        }),
    )
  }

  async fn create_snapshot(
    &self,
    _object: &CollabObject,
    _snapshot: Vec<u8>,
  ) -> Result<i64, Error> {
    todo!()
  }

  async fn send_update(
    &self,
    object: &CollabObject,
    _id: MsgId,
    update: Vec<u8>,
  ) -> Result<(), Error> {
    let workspace_id = object
      .get_workspace_id()
      .ok_or(anyhow::anyhow!("Invalid workspace id"))?;
    let value_size = update.len() as i32;
    let md5 = md5(&update);
    let update = format!("\\x{}", hex::encode(update));
    let insert_params = InsertParamsBuilder::new()
      .insert("oid", object.id.clone())
      .insert("partition_key", partition_key(&object.ty))
      .insert("value", update)
      .insert("uid", object.uid)
      .insert("md5", md5)
      .insert("workspace_id", workspace_id)
      .insert("value_size", value_size)
      .build();

    self
      .postgrest
      .from(&table_name(&object.ty))
      .insert(insert_params)
      .execute()
      .await?
      .success()
      .await?;
    Ok(())
  }

  async fn send_init_sync(
    &self,
    _object: &CollabObject,
    _id: MsgId,
    _init_update: Vec<u8>,
  ) -> Result<(), Error> {
    todo!()
  }

  async fn subscribe_remote_updates(&self, _object: &CollabObject) -> Option<RemoteUpdateReceiver> {
    todo!()
  }
}
