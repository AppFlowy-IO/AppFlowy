use flowy_database2::deps::{DatabaseCloudService, DatabaseSnapshot};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_database_updates(&self, _database_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_database_latest_snapshot(
    &self,
    _database_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }
}
