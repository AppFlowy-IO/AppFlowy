use anyhow::Error;

use flowy_folder_deps::cloud::{FolderCloudService, FolderData, FolderSnapshot, Workspace};
use lib_infra::future::FutureResult;

use crate::af_cloud::AFServer;

pub(crate) struct AFCloudFolderCloudServiceImpl<T>(pub T);

impl<T> FolderCloudService for AFCloudFolderCloudServiceImpl<T>
where
  T: AFServer,
{
  fn create_workspace(&self, _uid: i64, _name: &str) -> FutureResult<Workspace, Error> {
    FutureResult::new(async move { todo!() })
  }

  fn get_folder_data(&self, _workspace_id: &str) -> FutureResult<Option<FolderData>, Error> {
    FutureResult::new(async move { Ok(None) })
  }

  fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<FolderSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_folder_updates(
    &self,
    _workspace_id: &str,
    _uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn service_name(&self) -> String {
    "SelfHosted".to_string()
  }
}
