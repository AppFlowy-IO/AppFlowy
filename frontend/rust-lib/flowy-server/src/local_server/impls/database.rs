use flowy_database2::deps::{
  CollabObjectUpdate, CollabObjectUpdateByOid, DatabaseCloudService, DatabaseSnapshot,
};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_collab_update(&self, _object_id: &str) -> FutureResult<CollabObjectUpdate, FlowyError> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn batch_get_collab_updates(
    &self,
    _object_ids: Vec<String>,
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
