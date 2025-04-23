use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use lib_infra::async_trait::async_trait;
use std::path::PathBuf;
use uuid::Uuid;

#[async_trait]
pub trait AIUserService: Send + Sync + 'static {
  fn user_id(&self) -> Result<i64, FlowyError>;
  async fn is_local_model(&self) -> FlowyResult<bool>;
  fn workspace_id(&self) -> Result<Uuid, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
  fn application_root_dir(&self) -> Result<PathBuf, FlowyError>;
}
