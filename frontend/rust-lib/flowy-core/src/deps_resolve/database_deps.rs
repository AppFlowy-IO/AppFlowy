use std::sync::Arc;

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::RocksCollabDB;
use tokio::sync::RwLock;

use flowy_database2::deps::{DatabaseCloudService, DatabaseUser2};
use flowy_database2::DatabaseManager2;
use flowy_error::FlowyError;
use flowy_task::TaskDispatcher;
use flowy_user::services::UserSession;

pub struct Database2DepsResolver();

impl Database2DepsResolver {
  pub async fn resolve(
    user_session: Arc<UserSession>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
  ) -> Arc<DatabaseManager2> {
    let user = Arc::new(DatabaseUserImpl(user_session));
    Arc::new(DatabaseManager2::new(
      user,
      task_scheduler,
      collab_builder,
      cloud_service,
    ))
  }
}

struct DatabaseUserImpl(Arc<UserSession>);
impl DatabaseUser2 for DatabaseUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self
      .0
      .user_id()
      .map_err(|e| FlowyError::internal().context(e))
  }

  fn token(&self) -> Result<Option<String>, FlowyError> {
    self
      .0
      .token()
      .map_err(|e| FlowyError::internal().context(e))
  }

  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError> {
    self.0.get_collab_db()
  }
}
