use std::path::{Path, PathBuf};
use std::{collections::HashMap, sync::Arc, time::Duration};

use lazy_static::lazy_static;
use parking_lot::RwLock;

use collab_integrate::RocksCollabDB;
use flowy_error::{ErrorCode, FlowyError};
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{
  query_dsl::*,
  schema::{user_table, user_table::dsl},
  DBConnection, Database, ExpressionMethods,
};
use flowy_user_deps::entities::{UserProfile, UserWorkspace};

use crate::services::user_sql::UserTable;
use crate::services::user_workspace_sql::UserWorkspaceTable;

pub trait UserDBPath: Send + Sync + 'static {
  fn user_db_path(&self, uid: i64) -> PathBuf;
  fn collab_db_path(&self, uid: i64) -> PathBuf;
}

pub struct UserDB {
  paths: Box<dyn UserDBPath>,
}

impl UserDB {
  pub fn new(paths: impl UserDBPath) -> Self {
    Self {
      paths: Box::new(paths),
    }
  }

  /// Close the database connection for the user.
  pub(crate) fn close(&self, user_id: i64) -> Result<(), FlowyError> {
    if let Some(mut sqlite_dbs) = DB_MAP.try_write_for(Duration::from_millis(300)) {
      tracing::trace!("close sqlite db for user {}", user_id);
      sqlite_dbs.remove(&user_id);
    }

    if let Some(mut collab_dbs) = COLLAB_DB_MAP.try_write_for(Duration::from_millis(300)) {
      if let Some(db) = collab_dbs.remove(&user_id) {
        tracing::trace!("close collab db for user {}", user_id);
        drop(db);
      }
    }
    Ok(())
  }

  pub(crate) fn get_connection(&self, user_id: i64) -> Result<DBConnection, FlowyError> {
    let conn = self.get_pool(user_id)?.get()?;
    Ok(conn)
  }

  pub(crate) fn get_pool(&self, user_id: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
    let pool = open_user_db(self.paths.user_db_path(user_id), user_id)?;
    Ok(pool)
  }

  pub(crate) fn get_collab_db(&self, user_id: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
    let collab_db = open_collab_db(self.paths.collab_db_path(user_id), user_id)?;
    Ok(collab_db)
  }
}

pub fn open_user_db(
  db_path: impl AsRef<Path>,
  user_id: i64,
) -> Result<Arc<ConnectionPool>, FlowyError> {
  if let Some(database) = DB_MAP.read().get(&user_id) {
    return Ok(database.get_pool());
  }

  let mut write_guard = DB_MAP.write();
  tracing::debug!("open sqlite db {} at path: {:?}", user_id, db_path.as_ref());
  let db = flowy_sqlite::init(&db_path)
    .map_err(|e| FlowyError::internal().with_context(format!("open user db failed, {:?}", e)))?;
  let pool = db.get_pool();
  write_guard.insert(user_id.to_owned(), db);
  drop(write_guard);
  Ok(pool)
}

pub fn get_user_profile(pool: &Arc<ConnectionPool>, uid: i64) -> Result<UserProfile, FlowyError> {
  let uid = uid.to_string();
  let conn = pool.get()?;
  let user = dsl::user_table
    .filter(user_table::id.eq(&uid))
    .first::<UserTable>(&*conn)?;

  Ok(user.into())
}

pub fn get_user_workspace(
  pool: &Arc<ConnectionPool>,
  uid: i64,
) -> Result<Option<UserWorkspace>, FlowyError> {
  let conn = pool.get()?;
  let row = user_workspace_table::dsl::user_workspace_table
    .filter(user_workspace_table::uid.eq(uid))
    .first::<UserWorkspaceTable>(&*conn)?;
  Ok(Some(UserWorkspace::from(row)))
}

/// Open a collab db for the user. If the db is already opened, return the opened db.
///
fn open_collab_db(db_path: impl AsRef<Path>, uid: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
  if let Some(collab_db) = COLLAB_DB_MAP.read().get(&uid) {
    return Ok(collab_db.clone());
  }

  let mut write_guard = COLLAB_DB_MAP.write();
  tracing::trace!("open collab db {} at path: {:?}", uid, db_path.as_ref());
  let db = match RocksCollabDB::open(db_path) {
    Ok(db) => Ok(db),
    Err(err) => {
      tracing::error!("open collab db failed, {:?}", err);
      Err(FlowyError::new(ErrorCode::MultipleDBInstance, err))
    },
  }?;

  let db = Arc::new(db);
  write_guard.insert(uid.to_owned(), db.clone());
  drop(write_guard);
  Ok(db)
}

lazy_static! {
  static ref DB_MAP: RwLock<HashMap<i64, Database>> = RwLock::new(HashMap::new());
  static ref COLLAB_DB_MAP: RwLock<HashMap<i64, Arc<RocksCollabDB>>> = RwLock::new(HashMap::new());
}
