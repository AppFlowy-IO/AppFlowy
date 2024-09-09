use std::sync::Arc;

use anyhow::{anyhow, Error};
use collab_entity::CollabType;

use crate::local_server::LocalServerDB;
use flowy_folder_pub::cloud::{
  gen_workspace_id, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot, Workspace,
  WorkspaceRecord,
};
use flowy_folder_pub::entities::{PublishInfoResponse, PublishPayload};
use lib_infra::async_trait::async_trait;

pub(crate) struct LocalServerFolderCloudServiceImpl {
  #[allow(dead_code)]
  pub db: Arc<dyn LocalServerDB>,
}

#[async_trait]
impl FolderCloudService for LocalServerFolderCloudServiceImpl {
  async fn create_workspace(&self, uid: i64, name: &str) -> Result<Workspace, Error> {
    let name = name.to_string();
    Ok(Workspace::new(
      gen_workspace_id().to_string(),
      name.to_string(),
      uid,
    ))
  }

  async fn open_workspace(&self, _workspace_id: &str) -> Result<(), Error> {
    Ok(())
  }

  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, Error> {
    Ok(vec![])
  }

  async fn get_folder_data(
    &self,
    _workspace_id: &str,
    _uid: &i64,
  ) -> Result<Option<FolderData>, Error> {
    Ok(None)
  }

  async fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> Result<Vec<FolderSnapshot>, Error> {
    Ok(vec![])
  }

  async fn get_folder_doc_state(
    &self,
    _workspace_id: &str,
    _uid: i64,
    _collab_type: CollabType,
    _object_id: &str,
  ) -> Result<Vec<u8>, Error> {
    Err(anyhow!(
      "Local server doesn't support get collab doc state from remote"
    ))
  }

  async fn batch_create_folder_collab_objects(
    &self,
    _workspace_id: &str,
    _objects: Vec<FolderCollabParams>,
  ) -> Result<(), Error> {
    Ok(())
  }

  fn service_name(&self) -> String {
    "Local".to_string()
  }

  async fn publish_view(
    &self,
    _workspace_id: &str,
    _payload: Vec<PublishPayload>,
  ) -> Result<(), Error> {
    Err(anyhow!("Local server doesn't support publish view"))
  }

  async fn unpublish_views(
    &self,
    _workspace_id: &str,
    _view_ids: Vec<String>,
  ) -> Result<(), Error> {
    Err(anyhow!("Local server doesn't support unpublish views"))
  }

  async fn get_publish_info(&self, _view_id: &str) -> Result<PublishInfoResponse, Error> {
    Err(anyhow!(
      "Local server doesn't support get publish info from remote"
    ))
  }

  async fn set_publish_namespace(
    &self,
    _workspace_id: &str,
    _new_namespace: &str,
  ) -> Result<(), Error> {
    Err(anyhow!(
      "Local server doesn't support set publish namespace"
    ))
  }

  async fn get_publish_namespace(&self, _workspace_id: &str) -> Result<String, Error> {
    Err(anyhow!(
      "Local server doesn't support get publish namespace"
    ))
  }
}
