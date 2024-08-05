use std::sync::Arc;

use anyhow::{anyhow, Error};
use collab_entity::CollabType;

use flowy_folder_pub::cloud::{
  gen_workspace_id, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, Workspace,
  WorkspaceRecord,
};
use flowy_folder_pub::entities::{PublishInfoResponse, PublishPayload};
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
    _collab_type: CollabType,
    _object_id: &str,
  ) -> FutureResult<Vec<u8>, Error> {
    FutureResult::new(async {
      Err(anyhow!(
        "Local server doesn't support get collab doc state from remote"
      ))
    })
  }

  fn batch_create_folder_collab_objects(
    &self,
    _workspace_id: &str,
    _objects: Vec<FolderCollabParams>,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Err(anyhow!("Local server doesn't support create collab")) })
  }

  fn service_name(&self) -> String {
    "Local".to_string()
  }

  fn publish_view(
    &self,
    _workspace_id: &str,
    _payload: Vec<PublishPayload>,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Err(anyhow!("Local server doesn't support publish view")) })
  }

  fn unpublish_views(
    &self,
    _workspace_id: &str,
    _view_ids: Vec<String>,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async { Err(anyhow!("Local server doesn't support unpublish views")) })
  }

  fn get_publish_info(&self, _view_id: &str) -> FutureResult<PublishInfoResponse, Error> {
    FutureResult::new(async move {
      Err(anyhow!(
        "Local server doesn't support get publish info from remote"
      ))
    })
  }

  fn set_publish_namespace(
    &self,
    _workspace_id: &str,
    _new_namespace: &str,
  ) -> FutureResult<(), Error> {
    FutureResult::new(async {
      Err(anyhow!(
        "Local server doesn't support set publish namespace"
      ))
    })
  }

  fn get_publish_namespace(&self, _workspace_id: &str) -> FutureResult<String, Error> {
    FutureResult::new(async {
      Err(anyhow!(
        "Local server doesn't support get publish namespace"
      ))
    })
  }
}
