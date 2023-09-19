use anyhow::Error;
use collab_define::CollabType;

use flowy_database_deps::cloud::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudDatabaseCloudServiceImpl<T>(pub T);

impl<T> DatabaseCloudService for AFCloudDatabaseCloudServiceImpl<T>
where
  T: AFServer,
{
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

  fn get_collab_snapshots(
    &self,
    _object_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<DatabaseSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }
}
