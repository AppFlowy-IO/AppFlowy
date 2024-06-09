use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_database2::{DatabaseManager, DatabaseUser};
use flowy_database_pub::cloud::DatabaseCloudService;
use flowy_error::FlowyError;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_infra::priority_task::TaskDispatcher;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
pub struct DatabaseDepsResolver();

impl DatabaseDepsResolver {
  pub async fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
  ) -> Arc<DatabaseManager> {
    let user = Arc::new(DatabaseUserImpl(authenticate_user));
    Arc::new(DatabaseManager::new(
      user,
      task_scheduler,
      collab_builder,
      cloud_service,
    ))
  }
}

struct DatabaseUserImpl(Weak<AuthenticateUser>);
impl DatabaseUserImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl DatabaseUser for DatabaseUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self.upgrade_user()?.get_collab_db(uid)
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_id()
  }

  fn workspace_database_object_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_database_object_id()
  }
}
