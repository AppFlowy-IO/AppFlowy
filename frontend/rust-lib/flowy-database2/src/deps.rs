use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;
pub use collab_database::user::CollabObjectUpdate;
pub use collab_database::user::CollabObjectUpdateByOid;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub trait DatabaseUser2: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>;
  fn collab_db(&self, uid: i64) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

/// A trait for database cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
pub trait DatabaseCloudService: Send + Sync {
  fn get_collab_update(&self, object_id: &str) -> FutureResult<CollabObjectUpdate, FlowyError>;

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
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
