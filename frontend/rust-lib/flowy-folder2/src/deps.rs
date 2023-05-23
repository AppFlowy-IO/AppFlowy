use appflowy_integrate::RocksCollabDB;
pub use collab_folder::core::Workspace;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use std::sync::Arc;

/// [FolderUser] represents the user for folder.
pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>;
  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

/// [FolderCloudService] represents the cloud service for folder.
pub trait FolderCloudService: Send + Sync + 'static {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, FlowyError>;
}
