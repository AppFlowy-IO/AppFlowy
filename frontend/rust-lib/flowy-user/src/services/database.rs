use std::path::PathBuf;
use std::{collections::HashMap, sync::Arc, time::Duration};

use appflowy_integrate::RocksCollabDB;
use lazy_static::lazy_static;
use parking_lot::RwLock;

use flowy_error::{ErrorCode, FlowyError};
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
      tracing::error!("open user db failed, {:?}", e);
      FlowyError::new(ErrorCode::MultipleDBInstance, e)
    })?;
    let pool = db.get_pool();
    write_guard.insert(user_id.to_owned(), db);
    drop(write_guard);
    Ok(pool)
  }

  fn open_collab_db_if_need(&self, user_id: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
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
    dir.push("collab_db");

    tracing::trace!("open collab db {} at path: {:?}", user_id, dir);
    let db = match RocksCollabDB::open(dir) {
      Ok(db) => Ok(db),
      Err(err) => {
        tracing::error!("open collab db failed, {:?}", err);
        Err(FlowyError::new(ErrorCode::MultipleDBInstance, err))
      },
    }?;

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

  pub(crate) fn get_collab_db(&self, user_id: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
    let collab_db = self.open_collab_db_if_need(user_id)?;
    Ok(collab_db)
  }
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
}

impl UserTable {
  pub fn new(id: String, name: String, email: String, token: String, workspace_id: String) -> Self {
    Self {
      id,
      name,
      email,
      token,
      icon_url: "".to_owned(),
      workspace: workspace_id,
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
    UserTable {
      id: resp.user_id.to_string(),
      name: resp.name,
      token: resp.token.unwrap_or_default(),
      email: resp.email.unwrap_or_default(),
      workspace: resp.workspace_id,
      icon_url: "".to_string(),
      openai_key: "".to_string(),
    }
  }
}

impl From<SignInResponse> for UserTable {
  fn from(resp: SignInResponse) -> Self {
    UserTable {
      id: resp.user_id.to_string(),
      name: resp.name,
      token: resp.token.unwrap_or_default(),
      email: resp.email.unwrap_or_default(),
      workspace: resp.workspace_id,
      icon_url: "".to_string(),
      openai_key: "".to_string(),
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
