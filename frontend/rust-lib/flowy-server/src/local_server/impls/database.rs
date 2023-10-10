use anyhow::Error;
use collab_entity::CollabType;

use flowy_database_deps::cloud::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_collab_update(
    &self,
    _object_id: &str,
    _collab_type: CollabType,
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

  fn get_collab_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }
}
