use flowy_ai::ai_manager::AIUserService;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use lib_infra::async_trait::async_trait;
use std::path::PathBuf;
use std::sync::Arc;
use uuid::Uuid;

pub const USER_SIGN_IN_URL: &str = "sign_in_url";
pub const USER_UUID: &str = "uuid";
pub const USER_EMAIL: &str = "email";
pub const USER_DEVICE_ID: &str = "device_id";

/// Represents a user that is currently using the server.
#[async_trait]
pub trait LoginUserService: Send + Sync {
  /// different user might return different workspace id.
  fn workspace_id(&self) -> FlowyResult<Uuid>;

  fn user_id(&self) -> FlowyResult<i64>;
  async fn is_local_mode(&self) -> FlowyResult<bool>;

  fn get_sqlite_db(&self, uid: i64) -> Result<DBConnection, FlowyError>;
  fn application_root_dir(&self) -> Result<PathBuf, FlowyError>;
}

pub struct AIUserServiceImpl(pub Arc<dyn LoginUserService>);

#[async_trait]
impl AIUserService for AIUserServiceImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.0.user_id()
  }

  async fn is_local_model(&self) -> FlowyResult<bool> {
    self.0.is_local_mode().await
  }

  fn workspace_id(&self) -> Result<Uuid, FlowyError> {
    self.0.workspace_id()
  }

  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self.0.get_sqlite_db(uid)
  }

  fn application_root_dir(&self) -> Result<PathBuf, FlowyError> {
    self.0.application_root_dir()
  }
}
