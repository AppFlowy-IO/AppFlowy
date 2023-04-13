use std::sync::Arc;

use collab_persistence::CollabKV;
use flowy_database::manager::DatabaseManager;
use flowy_document2::manager::{DocumentManager as DocumentManager2, DocumentUser};
use flowy_error::FlowyError;
use flowy_user::services::UserSession;

pub struct Document2DepsResolver();
impl Document2DepsResolver {
  pub fn resolve(
    user_session: Arc<UserSession>,
    database_manager: &Arc<DatabaseManager>,
  ) -> Arc<DocumentManager2> {
    let user: Arc<dyn DocumentUser> = Arc::new(DocumentUserImpl(user_session.clone()));

    Arc::new(DocumentManager2::new(user.clone()))
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
