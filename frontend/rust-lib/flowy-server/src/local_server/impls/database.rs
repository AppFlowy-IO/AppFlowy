use flowy_database2::deps::{DatabaseCloudService, DatabaseSnapshot};
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_latest_snapshot(
    &self,
    _database_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }
}
