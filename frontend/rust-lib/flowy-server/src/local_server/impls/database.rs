use flowy_database2::deps::DatabaseCloudService;
use flowy_error::FlowyError;
use flowy_folder2::deps::{FolderCloudService, Workspace};
use flowy_folder2::gen_workspace_id;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

pub(crate) struct LocalServerDatabaseCloudServiceImpl();

impl DatabaseCloudService for LocalServerDatabaseCloudServiceImpl {
  fn get_latest_snapshot(&self, database_id: &str) -> FutureResult<Option<Vec<u8>>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }
}
