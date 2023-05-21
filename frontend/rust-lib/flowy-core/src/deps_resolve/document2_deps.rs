use std::sync::Arc;

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::RocksCollabDB;

use flowy_database2::DatabaseManager2;
use flowy_document2::manager::{DocumentManager, DocumentUser};
use flowy_error::FlowyError;
use flowy_user::services::UserSession;

pub struct Document2DepsResolver();
impl Document2DepsResolver {
  pub fn resolve(
    user_session: Arc<UserSession>,
    _database_manager: &Arc<DatabaseManager2>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
  ) -> Arc<DocumentManager> {
    let user: Arc<dyn DocumentUser> = Arc::new(DocumentUserImpl(user_session));
    Arc::new(DocumentManager::new(user.clone(), collab_builder))
  }
}

struct DocumentUserImpl(Arc<UserSession>);
impl DocumentUser for DocumentUserImpl {
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
