use flowy_error::FlowyError;
use flowy_folder2::deps::{FolderCloudService, Workspace};
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
}
