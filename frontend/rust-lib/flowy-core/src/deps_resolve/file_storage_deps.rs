use flowy_error::FlowyError;
use flowy_sqlite::DBConnection;
use flowy_storage::manager::{StorageManager, StorageUserService};
use flowy_storage_pub::cloud::StorageCloudService;
use flowy_user::services::authenticate_user::AuthenticateUser;
use std::sync::{Arc, Weak};

pub struct FileStorageResolver;

impl FileStorageResolver {
  pub fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    cloud_service: Arc<dyn StorageCloudService>,
    root: &str,
  ) -> Arc<StorageManager> {
    let user_service = FileStorageServiceImpl {
      user: authenticate_user,
      root_dir: root.to_owned(),
    };
    Arc::new(StorageManager::new(cloud_service, Arc::new(user_service)))
  }
}

struct FileStorageServiceImpl {
  user: Weak<AuthenticateUser>,
  root_dir: String,
}
impl FileStorageServiceImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .user
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl StorageUserService for FileStorageServiceImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_id()
  }

  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self.upgrade_user()?.get_sqlite_connection(uid)
  }

  fn get_application_root_dir(&self) -> &str {
    &self.root_dir
  }
}
