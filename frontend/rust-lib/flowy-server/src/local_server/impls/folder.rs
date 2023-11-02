use std::sync::Arc;

use anyhow::Error;

use flowy_folder_deps::cloud::{
  gen_workspace_id, FolderCloudService, FolderData, FolderSnapshot, Workspace,
};
use lib_infra::future::FutureResult;
use lib_infra::util::timestamp;

use crate::local_server::LocalServerDB;

pub(crate) struct LocalServerFolderCloudServiceImpl {
  pub db: Arc<dyn LocalServerDB>,
}

impl FolderCloudService for LocalServerFolderCloudServiceImpl {
  fn create_workspace(&self, _uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let name = name.to_string();
    FutureResult::new(async move {
      Ok(Workspace {
        id: gen_workspace_id().to_string(),
        name: name.to_string(),
        child_views: Default::default(),
        created_at: timestamp(),
      })
    })
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

  fn get_folder_updates(&self, workspace_id: &str, uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    let weak_db = Arc::downgrade(&self.db);
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      match weak_db.upgrade() {
        None => Ok(vec![]),
        Some(db) => {
          let updates = db.get_collab_updates(uid, &workspace_id)?;
          Ok(updates)
        },
      }
    })
  }

  fn service_name(&self) -> String {
    "Local".to_string()
  }
}
