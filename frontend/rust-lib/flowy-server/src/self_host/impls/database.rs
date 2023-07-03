use flowy_database2::deps::DatabaseCloudService;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub(crate) struct SelfHostedDatabaseCloudServiceImpl();

impl DatabaseCloudService for SelfHostedDatabaseCloudServiceImpl {
  fn get_latest_snapshot(&self, _database_id: &str) -> FutureResult<Option<Vec<u8>>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }
}
