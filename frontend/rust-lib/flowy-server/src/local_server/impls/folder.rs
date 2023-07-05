use flowy_error::FlowyError;
use flowy_folder2::deps::{FolderCloudService, FolderSnapshot, Workspace};
use flowy_folder2::gen_workspace_id;
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

pub(crate) struct LocalServerFolderCloudServiceImpl();

impl FolderCloudService for LocalServerFolderCloudServiceImpl {
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

  fn get_folder_latest_snapshot(
    &self,
    _workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, FlowyError> {
    FutureResult::new(async move { Ok(None) })
  }

  fn get_folder_updates(&self, _workspace_id: &str) -> FutureResult<Vec<Vec<u8>>, FlowyError> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn is_local_service(&self) -> bool {
    true
  }
}
