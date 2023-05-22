use appflowy_integrate::RocksCollabDB;
use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub trait FolderUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>;
  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

pub use collab_folder::core::Workspace;

pub trait FolderCloudService: Send + Sync + 'static {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, FlowyError>;
}
