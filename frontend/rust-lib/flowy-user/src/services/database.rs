use std::path::PathBuf;
use std::{collections::HashMap, sync::Arc, time::Duration};

use appflowy_integrate::RocksCollabDB;
use lazy_static::lazy_static;
use parking_lot::RwLock;

use flowy_error::{ErrorCode, FlowyError};
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{
  query_dsl::*,
  schema::{user_table, user_table::dsl},
  DBConnection, Database, ExpressionMethods,
};

use crate::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use crate::services::AuthType;

pub struct UserDB {
  root: String,
}

impl UserDB {
  pub fn new(db_dir: &str) -> Self {
    Self {
      root: db_dir.to_owned(),
    }
  }

  /// Close the database connection for the user.
  pub(crate) fn close(&self, user_id: i64) -> Result<(), FlowyError> {
    if let Some(mut sqlite_dbs) = DB_MAP.try_write_for(Duration::from_millis(300)) {
      sqlite_dbs.remove(&user_id);
    }

    if let Some(mut collab_dbs) = COLLAB_DB_MAP.try_write_for(Duration::from_millis(300)) {
      if let Some(db) = collab_dbs.remove(&user_id) {
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
    let pool = open_user_db(&self.root, user_id)?;
    Ok(pool)
  }

  pub(crate) fn get_collab_db(&self, user_id: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
    let collab_db = open_collab_db(&self.root, user_id)?;
    Ok(collab_db)
  }
}

pub fn open_user_db(root: &str, user_id: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
  if let Some(database) = DB_MAP.read().get(&user_id) {
    return Ok(database.get_pool());
  }

  let mut write_guard = DB_MAP.write();
  let dir = user_db_path_from_uid(root, user_id);
  tracing::debug!("open sqlite db {} at path: {:?}", user_id, dir);
  let db = flowy_sqlite::init(&dir)
    .map_err(|e| FlowyError::internal().context(format!("open user db failed, {:?}", e)))?;
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

pub fn user_db_path_from_uid(root: &str, uid: i64) -> PathBuf {
  let mut dir = PathBuf::new();
  dir.push(root);
  dir.push(uid.to_string());
  dir
}

/// Open a collab db for the user. If the db is already opened, return the opened db.
///
pub fn open_collab_db(root: &str, uid: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
  if let Some(collab_db) = COLLAB_DB_MAP.read().get(&uid) {
    return Ok(collab_db.clone());
  }

  let mut write_guard = COLLAB_DB_MAP.write();
  let dir = collab_db_path_from_uid(root, uid);
  tracing::trace!("open collab db {} at path: {:?}", uid, dir);
  let db = match RocksCollabDB::open(dir) {
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

pub fn collab_db_path_from_uid(root: &str, uid: i64) -> PathBuf {
  let mut dir = PathBuf::new();
  dir.push(root);
  dir.push(uid.to_string());
  dir.push("collab_db");
  dir
}

lazy_static! {
  static ref DB_MAP: RwLock<HashMap<i64, Database>> = RwLock::new(HashMap::new());
  static ref COLLAB_DB_MAP: RwLock<HashMap<i64, Arc<RocksCollabDB>>> = RwLock::new(HashMap::new());
}

/// The order of the fields in the struct must be the same as the order of the fields in the table.
/// Check out the [schema.rs] for table schema.
#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct UserTable {
  pub(crate) id: String,
  pub(crate) name: String,
  pub(crate) workspace: String,
  pub(crate) icon_url: String,
  pub(crate) openai_key: String,
  pub(crate) token: String,
  pub(crate) email: String,
  pub(crate) auth_type: i32,
}

impl UserTable {
  pub fn set_workspace(mut self, workspace: String) -> Self {
    self.workspace = workspace;
    self
  }
}

impl From<(SignUpResponse, AuthType)> for UserTable {
  fn from(params: (SignUpResponse, AuthType)) -> Self {
    let resp = params.0;
    UserTable {
      id: resp.user_id.to_string(),
      name: resp.name,
      token: resp.token.unwrap_or_default(),
      email: resp.email.unwrap_or_default(),
      workspace: resp.workspace_id,
      icon_url: "".to_string(),
      openai_key: "".to_string(),
      auth_type: params.1 as i32,
    }
  }
}

impl From<(SignInResponse, AuthType)> for UserTable {
  fn from(params: (SignInResponse, AuthType)) -> Self {
    let resp = params.0;
    let auth_type = params.1;
    UserTable {
      id: resp.user_id.to_string(),
      name: resp.name,
      token: resp.token.unwrap_or_default(),
      email: resp.email.unwrap_or_default(),
      workspace: resp.workspace_id,
      icon_url: "".to_string(),
      openai_key: "".to_string(),
      auth_type: auth_type as i32,
    }
  }
}

impl From<UserTable> for UserProfile {
  fn from(table: UserTable) -> Self {
    UserProfile {
      id: table.id.parse::<i64>().unwrap_or(0),
      email: table.email,
      name: table.name,
      token: table.token,
      icon_url: table.icon_url,
      openai_key: table.openai_key,
      workspace_id: table.workspace,
      auth_type: AuthType::from(table.auth_type),
    }
  }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[table_name = "user_table"]
pub struct UserTableChangeset {
  pub id: String,
  pub workspace: Option<String>, // deprecated
  pub name: Option<String>,
  pub email: Option<String>,
  pub icon_url: Option<String>,
  pub openai_key: Option<String>,
}

impl UserTableChangeset {
  pub fn new(params: UpdateUserProfileParams) -> Self {
    UserTableChangeset {
      id: params.id.to_string(),
      workspace: None,
      name: params.name,
      email: params.email,
      icon_url: params.icon_url,
      openai_key: params.openai_key,
    }
  }

  pub fn from_user_profile(user_profile: UserProfile) -> Self {
    UserTableChangeset {
      id: user_profile.id.to_string(),
      workspace: None,
      name: Some(user_profile.name),
      email: Some(user_profile.email),
      icon_url: Some(user_profile.icon_url),
      openai_key: Some(user_profile.openai_key),
    }
  }
}
