use crate::entities::PublishPayload;
pub use anyhow::Error;
use client_api::entity::{workspace_dto::PublishInfoView, PublishInfo};
use collab::entity::EncodedCollab;
use collab_entity::CollabType;
pub use collab_folder::{Folder, FolderData, Workspace};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

/// [FolderCloudService] represents the cloud service for folder.
#[async_trait]
pub trait FolderCloudService: Send + Sync + 'static {
  async fn get_folder_snapshots(
    &self,
    workspace_id: &str,
    limit: usize,
  ) -> Result<Vec<FolderSnapshot>, FlowyError>;

  async fn get_folder_doc_state(
    &self,
    workspace_id: &Uuid,
    uid: i64,
    collab_type: CollabType,
    object_id: &Uuid,
  ) -> Result<Vec<u8>, FlowyError>;

  async fn full_sync_collab_object(
    &self,
    workspace_id: &Uuid,
    params: FullSyncCollabParams,
  ) -> Result<(), FlowyError>;

  async fn batch_create_folder_collab_objects(
    &self,
    workspace_id: &Uuid,
    objects: Vec<FolderCollabParams>,
  ) -> Result<(), FlowyError>;

  fn service_name(&self) -> String;

  async fn publish_view(
    &self,
    workspace_id: &Uuid,
    payload: Vec<PublishPayload>,
  ) -> Result<(), FlowyError>;

  async fn unpublish_views(
    &self,
    workspace_id: &Uuid,
    view_ids: Vec<Uuid>,
  ) -> Result<(), FlowyError>;

  async fn get_publish_info(&self, view_id: &Uuid) -> Result<PublishInfo, FlowyError>;

  async fn set_publish_name(
    &self,
    workspace_id: &Uuid,
    view_id: Uuid,
    new_name: String,
  ) -> Result<(), FlowyError>;

  async fn set_publish_namespace(
    &self,
    workspace_id: &Uuid,
    new_namespace: String,
  ) -> Result<(), FlowyError>;

  async fn list_published_views(
    &self,
    workspace_id: &Uuid,
  ) -> Result<Vec<PublishInfoView>, FlowyError>;

  async fn get_default_published_view_info(
    &self,
    workspace_id: &Uuid,
  ) -> Result<PublishInfo, FlowyError>;

  async fn set_default_published_view(
    &self,
    workspace_id: &Uuid,
    view_id: uuid::Uuid,
  ) -> Result<(), FlowyError>;

  async fn remove_default_published_view(&self, workspace_id: &Uuid) -> Result<(), FlowyError>;

  async fn get_publish_namespace(&self, workspace_id: &Uuid) -> Result<String, FlowyError>;

  async fn import_zip(&self, file_path: &str) -> Result<(), FlowyError>;
}

#[derive(Debug)]
pub struct FolderCollabParams {
  pub object_id: Uuid,
  pub encoded_collab_v1: Vec<u8>,
  pub collab_type: CollabType,
}

#[derive(Debug)]
pub struct FullSyncCollabParams {
  pub object_id: Uuid,
  pub encoded_collab: EncodedCollab,
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
