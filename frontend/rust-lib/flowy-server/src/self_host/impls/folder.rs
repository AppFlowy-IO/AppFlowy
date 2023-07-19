use flowy_error::FlowyError;
use flowy_folder2::deps::{FolderCloudService, FolderData, FolderSnapshot, Workspace};
use flowy_folder2::gen_workspace_id;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

pub(crate) struct SelfHostedServerFolderCloudServiceImpl();

impl FolderCloudService for SelfHostedServerFolderCloudServiceImpl {
  fn create_workspace(&self, _uid: i64, name: &str) -> FutureResult<Workspace, FlowyError> {
    let name = name.to_string();
    FutureResult::new(async move {
      Ok(Workspace {
        id: gen_workspace_id(),
        name: name.to_string(),
        child_views: Default::default(),
        created_at: timestamp(),
      })
    })
  }

  fn get_folder_data(&self, _workspace_id: &str) -> FutureResult<Option<FolderData>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }

  fn get_folder_latest_snapshot(
    &self,
    _workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }

  fn get_folder_updates(
    &self,
    _workspace_id: &str,
    _uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn service_name(&self) -> String {
    "SelfHosted".to_string()
  }
}
