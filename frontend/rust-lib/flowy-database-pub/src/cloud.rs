use anyhow::Error;
use collab::core::collab::DataSource;
use collab_entity::CollabType;
use lib_infra::future::FutureResult;
use std::collections::HashMap;

pub type CollabDocStateByOid = HashMap<String, DataSource>;
pub type SummaryRowContent = HashMap<String, String>;
/// A trait for database cloud service.
/// Each kind of server should implement this trait. Check out the [AppFlowyServerProvider] of
/// [flowy-server] crate for more information.
///
/// returns the doc state of the object with the given object_id.
/// None if the object is not found.
pub trait DatabaseCloudService: Send + Sync {
  fn get_database_object_doc_state(
    &self,
    object_id: &str,
    collab_type: CollabType,
    workspace_id: &str,
  ) -> FutureResult<Option<Vec<u8>>, Error>;

  fn batch_get_database_object_doc_state(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
    workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error>;

  fn get_database_collab_object_snapshots(
    &self,
    object_id: &str,
    limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error>;

  fn summary_database_row(
    &self,
    workspace_id: &str,
    object_id: &str,
    summary_row: SummaryRowContent,
  ) -> FutureResult<String, Error>;
}

pub struct DatabaseSnapshot {
  pub snapshot_id: i64,
  pub database_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}
