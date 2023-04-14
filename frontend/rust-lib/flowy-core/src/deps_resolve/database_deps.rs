use std::sync::Arc;

use collab_persistence::CollabKV;
use tokio::sync::RwLock;

use flowy_client_ws::FlowyWebSocketConnect;
use flowy_database2::{DatabaseManager2, DatabaseUser2};
use flowy_error::FlowyError;
use flowy_task::TaskDispatcher;
use flowy_user::services::UserSession;

pub struct Database2DepsResolver();

impl Database2DepsResolver {
  pub async fn resolve(
    ws_conn: Arc<FlowyWebSocketConnect>,
    user_session: Arc<UserSession>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> Arc<DatabaseManager2> {
    let user = Arc::new(DatabaseUserImpl(user_session.clone()));
    Arc::new(DatabaseManager2::new(user, task_scheduler))
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

  fn token(&self) -> Result<String, FlowyError> {
    self
      .0
      .token()
      .map_err(|e| FlowyError::internal().context(e))
  }

  fn kv_db(&self) -> Result<Arc<CollabKV>, FlowyError> {
    self.0.get_kv_db()
  }
}
