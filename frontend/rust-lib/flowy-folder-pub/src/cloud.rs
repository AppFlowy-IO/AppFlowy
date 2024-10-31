use crate::entities::PublishPayload;
pub use anyhow::Error;
use client_api::entity::{workspace_dto::PublishInfoView, PublishInfo};
use collab_entity::CollabType;
pub use collab_folder::{Folder, FolderData, Workspace};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

/// [FolderCloudService] represents the cloud service for folder.
#[async_trait]
pub trait FolderCloudService: Send + Sync + 'static {
  /// Creates a new workspace for the user.
  /// Returns error if the cloud service doesn't support multiple workspaces
  async fn create_workspace(&self, uid: i64, name: &str) -> Result<Workspace, FlowyError>;

  async fn open_workspace(&self, workspace_id: &str) -> Result<(), FlowyError>;

  /// Returns all workspaces of the user.
  /// Returns vec![] if the cloud service doesn't support multiple workspaces
  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, FlowyError>;

  async fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> Result<Option<FolderData>, FlowyError>;

  async fn get_folder_snapshots(
    &self,
    workspace_id: &str,
    limit: usize,
  ) -> Result<Vec<FolderSnapshot>, FlowyError>;

  async fn get_folder_doc_state(
    &self,
    workspace_id: &str,
    uid: i64,
    collab_type: CollabType,
    object_id: &str,
  ) -> Result<Vec<u8>, FlowyError>;

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &str,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError>;

  fn service_name(&self) -> String;

  async fn publish_view(
    &self,
    workspace_id: &str,
    payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError>;

  async fn unpublish_views(
    &self,
    workspace_id: &str,
    view_ids: Vec<String>,
  ) -> Result<(), FlowyError>;

  async fn get_publish_info(&self, view_id: &str) -> Result<PublishInfo, FlowyError>;

  async fn set_publish_name(
    &self,
    workspace_id: &str,
    view_id: String,
    new_name: String,
  ) -> Result<(), FlowyError>;

  async fn set_publish_namespace(
    &self,
    workspace_id: &str,
    new_namespace: &str,
  ) -> Result<(), FlowyError>;

  async fn list_published_views(
    &self,
    workspace_id: &str,
  ) -> Result<Vec<PublishInfoView>, FlowyError>;

  async fn get_default_published_view_info(
    &self,
    workspace_id: &str,
  ) -> Result<PublishInfo, FlowyError>;

  async fn set_default_published_view(
    &self,
    workspace_id: &str,
    view_id: uuid::Uuid,
  ) -> Result<(), FlowyError>;

  async fn remove_default_published_view(&self, workspace_id: &str) -> Result<(), FlowyError>;

  async fn get_publish_namespace(&self, workspace_id: &str) -> Result<String, FlowyError>;

  async fn import_zip(&self, file_path: &str) -> Result<(), FlowyError>;
}

#[derive(Debug)]
pub struct FolderCollabParams {
  pub object_id: String,
  pub encoded_collab_v1: Vec<u8>,
  pub collab_type: CollabType,
}

pub struct FolderSnapshot {
  pub snapshot_id: i64,
  pub database_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}

pub fn gen_workspace_id() -> Uuid {
  uuid::Uuid::new_v4()
}

pub fn gen_view_id() -> Uuid {
  uuid::Uuid::new_v4()
}

#[derive(Debug)]
pub struct WorkspaceRecord {
  pub id: String,
  pub name: String,
  pub created_at: i64,
}
