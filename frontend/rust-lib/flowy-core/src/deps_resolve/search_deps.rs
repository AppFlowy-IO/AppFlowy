use flowy_error::FlowyError;
use flowy_search::native::indexer::SqliteSearchIndexerDB;
use flowy_search::SearchIndexer;
use flowy_sqlite::DBConnection;
use flowy_user::services::authenticate_user::AuthenticateUser;
use std::sync::{Arc, Weak};

pub struct SearchDepsResolver();
impl SearchDepsResolver {
  pub async fn resolve(authenticate_user: Weak<AuthenticateUser>) -> Arc<SearchIndexer> {
    let db_impl = SqliteSearchIndexerDBImpl(authenticate_user);
    Arc::new(SearchIndexer::new(Arc::new(db_impl)))
  }
}

struct SqliteSearchIndexerDBImpl(Weak<AuthenticateUser>);

impl SqliteSearchIndexerDB for SqliteSearchIndexerDBImpl {
  fn get_conn(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self
      .0
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .get_sqlite_connection(uid)
  }
}
