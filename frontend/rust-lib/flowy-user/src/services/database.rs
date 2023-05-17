use std::path::PathBuf;
use std::{collections::HashMap, sync::Arc, time::Duration};

use appflowy_integrate::RocksCollabDB;
use lazy_static::lazy_static;
use parking_lot::RwLock;

use flowy_error::FlowyError;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{schema::user_table, DBConnection, Database};

use crate::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};

pub struct UserDB {
  db_dir: String,
}

impl UserDB {
  pub fn new(db_dir: &str) -> Self {
    Self {
      db_dir: db_dir.to_owned(),
    }
  }

  fn open_user_db_if_need(&self, user_id: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
    if let Some(database) = DB_MAP.read().get(&user_id) {
      return Ok(database.get_pool());
    }

    let mut write_guard = DB_MAP.write();
    // The Write guard acquire exclusive access that will guarantee the user db only initialize once.
    match write_guard.get(&user_id) {
      None => {},
      Some(database) => return Ok(database.get_pool()),
    }

    let mut dir = PathBuf::new();
    dir.push(&self.db_dir);
    dir.push(user_id.to_string());
    let dir = dir.to_str().unwrap().to_owned();

    tracing::trace!("open user db {} at path: {}", user_id, dir);
    let db = flowy_sqlite::init(&dir).map_err(|e| {
      tracing::error!("open user: {} db failed, {:?}", user_id, e);
      FlowyError::internal().context(e)
    })?;
    let pool = db.get_pool();
    write_guard.insert(user_id.to_owned(), db);
    drop(write_guard);
    Ok(pool)
  }

  fn open_kv_db_if_need(&self, user_id: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
    if let Some(kv) = COLLAB_DB_MAP.read().get(&user_id) {
      return Ok(kv.clone());
    }

    let mut write_guard = COLLAB_DB_MAP.write();
    // The Write guard acquire exclusive access that will guarantee the user db only initialize once.
    match write_guard.get(&user_id) {
      None => {},
      Some(kv) => return Ok(kv.clone()),
    }

    let mut dir = PathBuf::new();
    dir.push(&self.db_dir);
    dir.push(user_id.to_string());

    tracing::trace!("open kv db {} at path: {:?}", user_id, dir);
    let db = RocksCollabDB::open(dir).map_err(|err| FlowyError::internal().context(err))?;
    let db = Arc::new(db);
    write_guard.insert(user_id.to_owned(), db.clone());
    drop(write_guard);
    Ok(db)
  }

  pub(crate) fn close_user_db(&self, user_id: i64) -> Result<(), FlowyError> {
    match DB_MAP.try_write_for(Duration::from_millis(300)) {
      None => Err(FlowyError::internal().context("Acquire write lock to close user db failed")),
      Some(mut write_guard) => {
        write_guard.remove(&user_id);
        Ok(())
      },
    }
  }

  pub(crate) fn get_connection(&self, user_id: i64) -> Result<DBConnection, FlowyError> {
    let conn = self.get_pool(user_id)?.get()?;
    Ok(conn)
  }

  pub(crate) fn get_pool(&self, user_id: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
    let pool = self.open_user_db_if_need(user_id)?;
    Ok(pool)
  }

  pub(crate) fn get_kv_db(&self, user_id: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
    let kv_db = self.open_kv_db_if_need(user_id)?;
    Ok(kv_db)
  }
}

lazy_static! {
  static ref DB_MAP: RwLock<HashMap<i64, Database>> = RwLock::new(HashMap::new());
  static ref COLLAB_DB_MAP: RwLock<HashMap<i64, Arc<RocksCollabDB>>> = RwLock::new(HashMap::new());
}

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[table_name = "user_table"]
pub struct UserTable {
  pub(crate) id: String,
  pub(crate) name: String,
  pub(crate) token: String,
  pub(crate) email: String,
  pub(crate) workspace: String, // deprecated
  pub(crate) icon_url: String,
  pub(crate) openai_key: String,
}

impl UserTable {
  pub fn new(id: String, name: String, email: String, token: String) -> Self {
    Self {
      id,
      name,
      email,
      token,
      icon_url: "".to_owned(),
      workspace: "".to_owned(),
      openai_key: "".to_owned(),
    }
  }

  pub fn set_workspace(mut self, workspace: String) -> Self {
    self.workspace = workspace;
    self
  }
}

impl From<SignUpResponse> for UserTable {
  fn from(resp: SignUpResponse) -> Self {
    UserTable::new(resp.user_id.to_string(), resp.name, resp.email, resp.token)
  }
}

impl From<SignInResponse> for UserTable {
  fn from(resp: SignInResponse) -> Self {
    UserTable::new(resp.user_id.to_string(), resp.name, resp.email, resp.token)
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
}
