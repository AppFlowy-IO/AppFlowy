use anyhow::Error;
use collab_plugins::cloud_storage::CollabType;

use flowy_database_deps::cloud::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};

use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_collab_update(
    &self,
    _object_id: &str,
    _object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdate, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn batch_get_collab_updates(
    &self,
    _object_ids: Vec<String>,
    _object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, Error> {
    FutureResult::new(async move { Ok(CollabObjectUpdateByOid::default()) })
  }

  fn get_collab_latest_snapshot(
    &self,
    _object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(None) })
  }
}
