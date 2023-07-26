use std::sync::Weak;

use appflowy_integrate::RocksCollabDB;
pub use collab_folder::core::{CollabOrigin, Folder, FolderData, Workspace};

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

/// [FolderUser] represents the user for folder.
pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>;
  fn collab_db(&self, uid: i64) -> Result<Weak<RocksCollabDB>, FlowyError>;
}

/// [FolderCloudService] represents the cloud service for folder.
pub trait FolderCloudService: Send + Sync + 'static {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, FlowyError>;

  fn add_member_to_workspace(
    &self,
    email: &str,
    workspace_id: &str,
  ) -> FutureResult<(), FlowyError>;

  fn remove_member_from_workspace(
    &self,
    email: &str,
    workspace_id: &str,
  ) -> FutureResult<(), FlowyError>;

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, FlowyError>;

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, FlowyError>;

  fn get_folder_updates(
    &self,
    workspace_id: &str,
    uid: i64,
  ) -> FutureResult<Vec<Vec<u8>>, FlowyError>;

  fn service_name(&self) -> String;
}

pub struct FolderSnapshot {
  pub snapshot_id: i64,
  pub database_id: String,
  pub data: Vec<u8>,
  pub created_at: i64,
}
