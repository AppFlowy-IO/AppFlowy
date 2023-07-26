use collab_plugins::cloud_storage::CollabType;
use flowy_database2::deps::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub(crate) struct SelfHostedDatabaseCloudServiceImpl();

impl DatabaseCloudService for SelfHostedDatabaseCloudServiceImpl {
  fn get_collab_update(
    &self,
    _object_id: &str,
    _object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdate, FlowyError> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn batch_get_collab_updates(
    &self,
    _object_ids: Vec<String>,
    _object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, FlowyError> {
    FutureResult::new(async move { Ok(CollabObjectUpdateByOid::default()) })
  }

  fn get_collab_latest_snapshot(
    &self,
    _object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }
}
