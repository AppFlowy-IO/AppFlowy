#![allow(unused_variables)]
use std::sync::Arc;

use client_api::entity::workspace_dto::PublishInfoView;
use client_api::entity::PublishInfo;
use collab_entity::CollabType;
use flowy_error::FlowyError;
use flowy_folder_pub::cloud::{
  gen_workspace_id, FolderCloudService, FolderCollabParams, FolderData, FolderSnapshot,
  FullSyncCollabParams, Workspace, WorkspaceRecord,
};
use flowy_folder_pub::entities::PublishPayload;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub(crate) struct LocalServerFolderCloudServiceImpl;

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

  async fn open_workspace(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    Ok(())
  }

  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, FlowyError> {
    Ok(vec![])
  }

  async fn get_folder_data(
    &self,
    workspace_id: &Uuid,
    uid: &i64,
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
    workspace_id: &Uuid,
    uid: i64,
    collab_type: CollabType,
    object_id: &Uuid,
  ) -> Result<Vec<u8>, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &Uuid,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  fn service_name(&self) -> String {
    "Local".to_string()
  }

  async fn publish_view(
    &self,
    workspace_id: &Uuid,
    payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn unpublish_views(
    &self,
    workspace_id: &Uuid,
    view_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_publish_info(&self, view_id: &Uuid) -> Result<PublishInfo, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn set_publish_namespace(
    &self,
    workspace_id: &Uuid,
    new_namespace: String,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_publish_namespace(&self, workspace_id: &Uuid) -> Result<String, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn set_publish_name(
    &self,
    workspace_id: &Uuid,
    view_id: Uuid,
    new_name: String,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn list_published_views(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<PublishInfoView>, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn get_default_published_view_info(
    &self,
    workspace_id: &Uuid,
  ) -> Result<PublishInfo, FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn set_default_published_view(
    &self,
    workspace_id: &Uuid,
    view_id: uuid::Uuid,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn remove_default_published_view(&self, workspace_id: &Uuid) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn import_zip(&self, _file_path: &str) -> Result<(), FlowyError> {
    Err(FlowyError::local_version_not_support())
  }

  async fn full_sync_collab_object(
    &self,
    workspace_id: &Uuid,
    params: FullSyncCollabParams,
  ) -> Result<(), FlowyError> {
    Ok(())
  }
}
