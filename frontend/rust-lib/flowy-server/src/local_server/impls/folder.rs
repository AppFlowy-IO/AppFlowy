use std::sync::Arc;

use anyhow::{anyhow, Error};

use flowy_folder_deps::cloud::{
  gen_workspace_id, FolderCloudService, FolderData, FolderSnapshot, Workspace, WorkspaceRecord,
};
use lib_infra::future::FutureResult;

use crate::local_server::LocalServerDB;

pub(crate) struct LocalServerFolderCloudServiceImpl {
  #[allow(dead_code)]
  pub db: Arc<dyn LocalServerDB>,
}

impl FolderCloudService for LocalServerFolderCloudServiceImpl {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let name = name.to_string();
    FutureResult::new(async move {
      Ok(Workspace::new(
        gen_workspace_id().to_string(),
        name.to_string(),
        uid,
      ))
    })
  }

  fn open_workspace(&self, _workspace_id: &str) -> FutureResult<(), Error> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_all_workspace(&self) -> FutureResult<Vec<WorkspaceRecord>, Error> {
    FutureResult::new(async { Ok(vec![]) })
  }

  fn get_folder_data(
    &self,
    _workspace_id: &str,
    _uid: &i64,
  ) -> FutureResult<Option<FolderData>, Error> {
    FutureResult::new(async move { Ok(None) })
  }

  fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> FutureResult<Vec<FolderSnapshot>, Error> {
    FutureResult::new(async move { Ok(vec![]) })
  }

  fn get_folder_doc_state(
    &self,
    _workspace_id: &str,
    _uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, Error> {
    FutureResult::new(async {
      Err(anyhow!(
        "Local server doesn't support get folder doc state from remote"
      ))
    })
  }

  fn service_name(&self) -> String {
    "Local".to_string()
  }
}
