use anyhow::Error;
use collab_entity::CollabType;

use flowy_database_pub::cloud::{CollabDocStateByOid, DatabaseCloudService, DatabaseSnapshot};
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_database_object_doc_state(
    &self,
    _object_id: &str,
    _collab_type: CollabType,
    _workspace_id: &str,
  ) -> FutureResult<Vec<u8>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn batch_get_database_object_doc_state(
    &self,
    _object_ids: Vec<String>,
    _object_ty: CollabType,
    _workspace_id: &str,
  ) -> FutureResult<CollabDocStateByOid, Error> {
    FutureResult::new(async move { Ok(CollabDocStateByOid::default()) })
  }

  fn get_database_collab_object_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }
}
