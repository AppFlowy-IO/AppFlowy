use crate::entities::{PublishInfoResponse, PublishPayload};
pub use anyhow::Error;
use collab_entity::CollabType;
pub use collab_folder::{Folder, FolderData, Workspace};
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;
use uuid::Uuid;

/// [FolderCloudService] represents the cloud service for folder.
#[async_trait]
pub trait FolderCloudService: Send + Sync + 'static {
  /// Creates a new workspace for the user.
  /// Returns error if the cloud service doesn't support multiple workspaces
  async fn create_workspace(&self, uid: i64, name: &str) -> Result<Workspace, Error>;

  async fn open_workspace(&self, workspace_id: &str) -> Result<(), Error>;

  /// Returns all workspaces of the user.
  /// Returns vec![] if the cloud service doesn't support multiple workspaces
  async fn get_all_workspace(&self) -> Result<Vec<WorkspaceRecord>, Error>;

  async fn get_folder_data(
    &self,
    workspace_id: &str,
    uid: &i64,
  ) -> Result<Option<FolderData>, Error>;

  async fn get_folder_snapshots(
    &self,
    workspace_id: &str,
    limit: usize,
  ) -> Result<Vec<FolderSnapshot>, Error>;

  async fn get_folder_doc_state(
    &self,
    workspace_id: &str,
    uid: i64,
    collab_type: CollabType,
    object_id: &str,
  ) -> Result<Vec<u8>, Error>;

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &str,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), Error>;

  fn service_name(&self) -> String;

  async fn publish_view(
    &self,
    workspace_id: &str,
    payload: Vec<PublishPayload>,
  ) -> Result<(), Error>;

  async fn unpublish_views(&self, workspace_id: &str, view_ids: Vec<String>) -> Result<(), Error>;

  async fn get_publish_info(&self, view_id: &str) -> Result<PublishInfoResponse, Error>;

  async fn set_publish_namespace(
    &self,
    workspace_id: &str,
    new_namespace: &str,
  ) -> Result<(), Error>;

  async fn get_publish_namespace(&self, workspace_id: &str) -> Result<String, Error>;
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
