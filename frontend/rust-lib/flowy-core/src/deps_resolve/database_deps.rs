use std::sync::{Arc, Weak};

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::RocksCollabDB;
use tokio::sync::RwLock;

use flowy_database2::{DatabaseManager, DatabaseUser};
use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_error::FlowyError;
use flowy_task::TaskDispatcher;
use flowy_user::manager::UserManager;

pub struct DatabaseDepsResolver();

impl DatabaseDepsResolver {
  pub async fn resolve(
    user_manager: Weak<UserManager>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
  ) -> Arc<DatabaseManager> {
    let user = Arc::new(DatabaseUserImpl(user_manager));
    Arc::new(DatabaseManager::new(
      user,
      task_scheduler,
      collab_builder,
      cloud_service,
    ))
  }
}

struct DatabaseUserImpl(Weak<UserManager>);
impl DatabaseUser for DatabaseUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .user_id()
  }

  fn token(&self) -> Result<Option<String>, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .token()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<RocksCollabDB>, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .get_collab_db(uid)
  }
}
