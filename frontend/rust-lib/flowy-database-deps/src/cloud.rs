use std::collections::HashMap;

use anyhow::Error;
use collab::core::collab::CollabDocState;
use collab_entity::CollabType;

use lib_infra::future::FutureResult;

pub type CollabDocStateByOid = HashMap<String, CollabDocState>;

/// A trait for database cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
pub trait DatabaseCloudService: Send + Sync {
  /// The suffix 'db' in the method name serves as a workaround to avoid naming conflicts with the existing method `get_collab_doc_state`.
  fn get_collab_doc_state_db(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabDocState, Error>;

  /// The suffix 'db' in the method name serves as a workaround to avoid naming conflicts with the existing method `get_collab_doc_state`.
  fn batch_get_collab_doc_state_db(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error>;

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
