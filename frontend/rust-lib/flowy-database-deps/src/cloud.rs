use std::collections::HashMap;

use anyhow::Error;
use collab_entity::CollabType;

use lib_infra::future::FutureResult;

pub type CollabObjectUpdateByOid = HashMap<String, CollabObjectUpdate>;
pub type CollabObjectUpdate = Vec<Vec<u8>>;

/// A trait for database cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
pub trait DatabaseCloudService: Send + Sync {
  fn get_collab_update(
    &self,
    object_id: &str,
    collab_type: CollabType,
  ) -> FutureResult<CollabObjectUpdate, Error>;

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, Error>;

  fn get_collab_snapshots(
    &self,
    object_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error>;
}

pub struct DatabaseSnapshot {
  pub snapshot_id: i64,
  pub database_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}
