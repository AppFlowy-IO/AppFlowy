use std::sync::Arc;

use crate::local_server::LocalServerDB;
use collab_entity::CollabType;
use flowy_error::FlowyError;
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
  async fn create_workspace(&self, uid: i64, name: &str) -> Result<Workspace, FlowyError> {
    let name = name.to_string();
    Ok(Workspace::new(
      gen_workspace_id().to_string(),
      name.to_string(),
      uid,
    ))
  }

  async fn open_workspace(&self, _workspace_id: &str) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, FlowyError> {
    Ok(vec![])
  }

  async fn get_folder_data(
    &self,
    _workspace_id: &str,
    _uid: &i64,
  ) -> Result<Option<FolderData>, FlowyError> {
    Ok(None)
  }

  async fn get_folder_snapshots(
    &self,
    _workspace_id: &str,
    _limit: usize,
  ) -> Result<Vec<FolderSnapshot>, FlowyError> {
    Ok(vec![])
  }

  async fn get_folder_doc_state(
    &self,
    _workspace_id: &str,
    _uid: i64,
    _collab_type: CollabType,
    _object_id: &str,
  ) -> Result<Vec<u8>, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn batch_create_folder_collab_objects(
    &self,
    _workspace_id: &str,
    _objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  fn service_name(&self) -> String {
    "Local".to_string()
  }

  async fn publish_view(
    &self,
    _workspace_id: &str,
    _payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn unpublish_views(
    &self,
    _workspace_id: &str,
    _view_ids: Vec<String>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_publish_info(&self, _view_id: &str) -> Result<PublishInfoResponse, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn set_publish_namespace(
    &self,
    _workspace_id: &str,
    _new_namespace: &str,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_publish_namespace(&self, _workspace_id: &str) -> Result<String, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn import_zip(&self, _file_path: &str) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }
}
