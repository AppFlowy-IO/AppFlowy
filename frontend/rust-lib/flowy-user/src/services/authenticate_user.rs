use crate::migrations::session_migration::migrate_session_with_user_uuid;
use crate::services::db::UserDB;
use crate::services::entities::{UserConfig, UserPaths};
use crate::services::sqlite_sql::user_sql::vacuum_database;
use collab_integrate::CollabKVDB;

use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::kv::StorePreferences;
use flowy_sqlite::DBConnection;
use flowy_user_pub::entities::UserWorkspace;
use flowy_user_pub::session::Session;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tracing::{error, info};

const SQLITE_VACUUM_042: &str = "sqlite_vacuum_042_version";

pub struct AuthenticateUser {
  pub user_config: UserConfig,
  pub(crate) database: Arc<UserDB>,
  pub(crate) user_paths: UserPaths,
  store_preferences: Arc<StorePreferences>,
  session: Arc<parking_lot::RwLock<Option<Session>>>,
}

impl AuthenticateUser {
  pub fn new(user_config: UserConfig, store_preferences: Arc<StorePreferences>) -> Self {
    let user_paths = UserPaths::new(user_config.storage_path.clone());
    let database = Arc::new(UserDB::new(user_paths.clone()));
    let session = Arc::new(parking_lot::RwLock::new(None));
    *session.write() =
      migrate_session_with_user_uuid(&user_config.session_cache_key, &store_preferences);
    Self {
      user_config,
      database,
      user_paths,
      store_preferences,
      session,
    }
  }

  pub fn vacuum_database_if_need(&self) {
    if !self.store_preferences.get_bool(SQLITE_VACUUM_042) {
      if let Ok(session) = self.get_session() {
        let _ = self.store_preferences.set_bool(SQLITE_VACUUM_042, true);
        if let Ok(conn) = self.database.get_connection(session.user_id) {
          info!("vacuum database 042");
          if let Err(err) = vacuum_database(conn) {
            error!("vacuum database error: {:?}", err);
          }
        }
      }
    }
  }

  pub fn user_id(&self) -> FlowyResult<i64> {
    let session = self.get_session()?;
    Ok(session.user_id)
  }

  pub fn device_id(&self) -> FlowyResult<String> {
    Ok(self.user_config.device_id.to_string())
  }

  pub fn workspace_id(&self) -> FlowyResult<String> {
    let session = self.get_session()?;
    Ok(session.user_workspace.id)
  }

  pub fn workspace_database_object_id(&self) -> FlowyResult<String> {
    let session = self.get_session()?;
    Ok(session.user_workspace.workspace_database_object_id.clone())
  }

  pub fn get_collab_db(&self, uid: i64) -> FlowyResult<Weak<CollabKVDB>> {
    self
      .database
      .get_collab_db(uid)
      .map(|collab_db| Arc::downgrade(&collab_db))
  }

  pub fn get_sqlite_connection(&self, uid: i64) -> FlowyResult<DBConnection> {
    self.database.get_connection(uid)
  }

  pub fn get_index_path(&self) -> PathBuf {
    let uid = self.user_id().unwrap_or(0);
    PathBuf::from(self.user_paths.user_data_dir(uid)).join("indexes")
  }

  pub fn close_db(&self) -> FlowyResult<()> {
    let session = self.get_session()?;
    info!("Close db for user: {}", session.user_id);
    self.database.close(session.user_id)?;
    Ok(())
  }

  pub fn set_session(&self, session: Option<Session>) -> Result<(), FlowyError> {
    match &session {
      None => {
        let removed_session = self.session.write().take();
        info!("remove session: {:?}", removed_session);
        self
          .store_preferences
          .remove(self.user_config.session_cache_key.as_ref());
        Ok(())
      },
      Some(session) => {
        info!("Set current session: {:?}", session);
        self.session.write().replace(session.clone());
        self
          .store_preferences
          .set_object(&self.user_config.session_cache_key, session.clone())
          .map_err(internal_error)?;
        Ok(())
      },
    }
  }

  pub fn set_user_workspace(&self, user_workspace: UserWorkspace) -> FlowyResult<()> {
    let mut session = self.get_session()?;
    session.user_workspace = user_workspace;
    self.set_session(Some(session))
  }

  pub fn get_session(&self) -> FlowyResult<Session> {
    if let Some(session) = (self.session.read()).clone() {
      return Ok(session);
    }

    match self
      .store_preferences
      .get_object::<Session>(&self.user_config.session_cache_key)
    {
      None => Err(FlowyError::new(
        ErrorCode::RecordNotFound,
        "User is not logged in",
      )),
      Some(session) => {
        self.session.write().replace(session.clone());
        Ok(session)
      },
    }
  }
}
