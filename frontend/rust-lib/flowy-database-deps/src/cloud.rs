use std::collections::HashMap;

use collab_plugins::cloud_storage::CollabType;

use flowy_error::FlowyError;
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
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdate, FlowyError>;

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, FlowyError>;

  fn get_collab_latest_snapshot(
    &self,
    object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, FlowyError>;
}

pub struct DatabaseSnapshot {
  pub snapshot_id: i64,
  pub database_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}
