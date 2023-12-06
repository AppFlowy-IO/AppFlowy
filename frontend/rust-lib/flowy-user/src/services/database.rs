use std::path::{Path, PathBuf};
use std::{collections::HashMap, fs, io, sync::Arc, time::Duration};

use chrono::Local;
use lazy_static::lazy_static;
use parking_lot::RwLock;
use tracing::{error, event, info, instrument};

use collab_integrate::{PersistenceError, RocksCollabDB, YrsDocAction};
use flowy_error::FlowyError;
use flowy_sqlite::schema::user_workspace_table;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{
  query_dsl::*,
  schema::{user_table, user_table::dsl},
  DBConnection, Database, ExpressionMethods,
};
use flowy_user_deps::entities::{UserProfile, UserWorkspace};
use lib_dispatch::prelude::af_spawn;
use lib_infra::file_util::{unzip_and_replace, zip_folder};

use crate::services::user_sql::UserTable;
use crate::services::user_workspace_sql::UserWorkspaceTable;

pub trait UserDBPath: Send + Sync + 'static {
  fn user_db_path(&self, uid: i64) -> PathBuf;
  fn collab_db_path(&self, uid: i64) -> PathBuf;
  fn collab_db_history(&self, uid: i64, create_if_not_exist: bool) -> std::io::Result<PathBuf>;
}

pub struct UserDB {
  paths: Box<dyn UserDBPath>,
}

impl UserDB {
  pub fn new(paths: impl UserDBPath) -> Self {
    // if let Some(mut db) = DB_MAP.try_write_for(Duration::from_millis(300)) {
    //   info!("clear sqlite db map");
    //   db.clear();
    // }
    //
    // if let Some(mut collab_db) = COLLAB_DB_MAP.try_write_for(Duration::from_millis(300)) {
    //   info!("clear collab db map");
    //   collab_db.clear();
    // }
    Self {
      paths: Box::new(paths),
    }
  }

  /// Performs a conditional backup or restoration of the collaboration database (CollabDB) for a specific user.
  ///
  /// This function takes a user ID and conducts the following operations:
  ///
  /// **Backup or Restoration**:
  ///   - If the CollabDB exists, it tries to open the database:
  ///       - **Successful Open**: If the database opens successfully, it attempts to back it up.
  ///       - **Failed Open**: If the database cannot be opened, it indicates a potential issue, and the function
  ///         attempts to restore the database from the latest backup.
  ///   - If the CollabDB does not exist, it immediately attempts to restore from the latest backup.
  ///
  #[instrument(level = "debug", skip_all)]
  pub fn backup_or_restore(&self, uid: i64, workspace_id: &str) {
    // Obtain the path for the collaboration database.
    let collab_db_path = self.paths.collab_db_path(uid);

    // Obtain the history folder path, proceed if successful.
    if let Ok(history_folder) = self.paths.collab_db_history(uid, true) {
      // Initialize the backup utility for the collaboration database.
      let zip_backup = CollabDBZipBackup::new(collab_db_path.clone(), history_folder);

      if collab_db_path.exists() {
        // Validate the existing collaboration database.
        let is_ok = validate_collab_db(&collab_db_path, uid, workspace_id);

        if is_ok {
          // If database is valid, update the shared map and initiate backup.
          // Asynchronous backup operation.
          af_spawn(async move {
            if let Err(err) = tokio::task::spawn_blocking(move || zip_backup.backup()).await {
              error!("Backup of collab db failed: {:?}", err);
            }
          });
        } else if let Err(err) = zip_backup.restore_latest_backup() {
          // If validation fails, attempt to restore from the latest backup.
          error!("Restoring collab db failed: {:?}", err);
        }
      }
    }
  }

  #[instrument(level = "debug", skip_all)]
  pub fn restore_if_need(&self, uid: i64, workspace_id: &str) {
    if let Ok(history_folder) = self.paths.collab_db_history(uid, false) {
      let collab_db_path = self.paths.collab_db_path(uid);
      let is_ok = validate_collab_db(&collab_db_path, uid, workspace_id);

      if !is_ok {
        let zip_backup = CollabDBZipBackup::new(collab_db_path, history_folder);
        if let Err(err) = zip_backup.restore_latest_backup() {
          error!("restore collab db failed, {:?}", err);
        }
      }
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
        let _ = db.flush();
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
    let collab_db = open_collab_db(
      // self.paths.user_db_path(user_id),
      self.paths.collab_db_path(user_id),
      // self.paths.collab_db_history(user_id, false).ok(),
      user_id,
    )?;
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
fn open_collab_db(
  collab_db_path: impl AsRef<Path>,
  uid: i64,
) -> Result<Arc<RocksCollabDB>, PersistenceError> {
  if let Some(collab_db) = COLLAB_DB_MAP.read().get(&uid) {
    return Ok(collab_db.clone());
  }

  let mut write_guard = COLLAB_DB_MAP.write();
  info!(
    "open collab db for user {} at path: {:?}",
    uid,
    collab_db_path.as_ref()
  );
  let db = match RocksCollabDB::open(&collab_db_path) {
    Ok(db) => Ok(db),
    Err(err) => {
      error!("open collab db error, {:?}", err);
      Err(err)
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

pub struct CollabDBZipBackup {
  collab_db_path: PathBuf,
  history_folder: PathBuf,
}

impl CollabDBZipBackup {
  fn new(collab_db_path: PathBuf, history_folder: PathBuf) -> Self {
    Self {
      collab_db_path,
      history_folder,
    }
  }

  #[instrument(name = "backup_collab_db", skip_all, err)]
  pub fn backup(&self) -> io::Result<()> {
    let today_zip_file = self
      .history_folder
      .join(format!("collab_db_{}.zip", today_zip_timestamp()));

    // Remove today's existing zip file if it exists
    if !today_zip_file.exists() {
      // Create a backup for today
      event!(
        tracing::Level::INFO,
        "Backup collab db to {:?}",
        today_zip_file
      );
      zip_folder(&self.collab_db_path, &today_zip_file)?;
    }

    // Clean up old backups
    self.clean_old_backups()?;

    Ok(())
  }

  #[instrument(skip_all, err)]
  pub fn restore_latest_backup(&self) -> io::Result<()> {
    let mut latest_zip: Option<(String, PathBuf)> = None;
    for entry in fs::read_dir(&self.history_folder)? {
      let entry = entry?;
      let path = entry.path();
      if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("zip") {
        if let Some(file_name) = path.file_stem().and_then(|s| s.to_str()) {
          if let Some(timestamp_str) = file_name.strip_prefix("collab_db_") {
            match latest_zip {
              Some((latest_timestamp, _)) if timestamp_str > latest_timestamp.as_str() => {
                latest_zip = Some((timestamp_str.to_string(), path));
              },
              None => latest_zip = Some((timestamp_str.to_string(), path)),
              _ => {},
            }
          }
        }
      }
    }

    let restore_path = latest_zip
      .map(|(_, path)| path)
      .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "No backup folder found"))?;

    unzip_and_replace(&restore_path, &self.collab_db_path)?;
    info!("Restore collab db from {:?}", restore_path);
    Ok(())
  }

  fn clean_old_backups(&self) -> io::Result<()> {
    let mut backups = Vec::new();
    let threshold_date = Local::now() - chrono::Duration::days(10);

    // Collect all backup files
    for entry in fs::read_dir(&self.history_folder)? {
      let entry = entry?;
      let path = entry.path();
      if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("zip") {
        let filename = path
          .file_stem()
          .and_then(|s| s.to_str())
          .unwrap_or_default();
        let date_str = filename.split('_').last().unwrap_or("");
        backups.push((date_str.to_string(), path));
      }
    }

    // Sort backups by date (oldest first)
    backups.sort_by(|a, b| a.0.cmp(&b.0));

    // Remove backups older than 10 days
    let threshold_str = threshold_date.format(zip_time_format()).to_string();

    // If there are more than 10 backups, remove the oldest ones
    while backups.len() > 10 {
      if let Some((date_str, path)) = backups.first() {
        if date_str < &threshold_str {
          info!("Remove old backup file: {:?}", path);
          fs::remove_file(path)?;
          backups.remove(0);
        } else {
          break;
        }
      }
    }

    Ok(())
  }
}

fn today_zip_timestamp() -> String {
  Local::now().format(zip_time_format()).to_string()
}

fn zip_time_format() -> &'static str {
  "%Y%m%d"
}

pub(crate) fn validate_collab_db(
  collab_db_path: impl AsRef<Path>,
  uid: i64,
  workspace_id: &str,
) -> bool {
  // Attempt to open the collaboration database using the workspace_id. The workspace_id must already
  // exist in the collab database. If it does not, it may be indicative of corruption in the collab database
  // due to other factors.
  info!(
    "open collab db to validate data integration for user {} at path: {:?}",
    uid,
    collab_db_path.as_ref()
  );

  match open_collab_db(&collab_db_path, uid) {
    Ok(db) => {
      let read_txn = db.read_txn();
      read_txn.is_exist(uid, workspace_id)
    },
    // return false if the error is not related to corruption
    Err(err) => !matches!(
      err,
      PersistenceError::RocksdbCorruption(_) | PersistenceError::RocksdbRepairFail(_)
    ),
  }
}
