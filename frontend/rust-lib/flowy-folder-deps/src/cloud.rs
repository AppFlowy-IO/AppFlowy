pub use collab_folder::core::{Folder, FolderData, Workspace};

pub use anyhow::Error;

use lib_infra::future::FutureResult;
use uuid::Uuid;

/// [FolderCloudService] represents the cloud service for folder.
pub trait FolderCloudService: Send + Sync + 'static {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error>;

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, Error>;

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, Error>;

  fn get_folder_updates(&self, workspace_id: &str, uid: i64) -> FutureResult<Vec<Vec<u8>>, Error>;

  fn service_name(&self) -> String;
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
