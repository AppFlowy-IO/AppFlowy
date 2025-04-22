use crate::migrations::session_migration::migrate_session;
use crate::services::db::UserDB;
use crate::services::entities::{UserConfig, UserPaths};
use collab_integrate::CollabKVDB;

use arc_swap::ArcSwapOption;
use collab_plugins::local_storage::kv::doc::CollabKVAction;
use collab_plugins::local_storage::kv::KVTransactionDB;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::DBConnection;
use flowy_user_pub::entities::{AuthType, UserWorkspace};
use flowy_user_pub::session::Session;
use flowy_user_pub::sql::{select_user_workspace, select_user_workspace_type};
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::{Arc, Weak};
use tracing::info;
use uuid::Uuid;

pub struct AuthenticateUser {
  pub user_config: UserConfig,
  pub(crate) database: Arc<UserDB>,
  pub(crate) user_paths: UserPaths,
  store_preferences: Arc<KVStorePreferences>,
  session: ArcSwapOption<Session>,
}

impl AuthenticateUser {
  pub fn new(user_config: UserConfig, store_preferences: Arc<KVStorePreferences>) -> Self {
    let user_paths = UserPaths::new(user_config.storage_path.clone());
    let database = Arc::new(UserDB::new(user_paths.clone()));
    let session = migrate_session(&user_config.session_cache_key, &store_preferences).map(Arc::new);
    Self {
      user_config,
      database,
      user_paths,
      store_preferences,
      session: ArcSwapOption::from(session),
    }
  }

  pub fn user_id(&self) -> FlowyResult<i64> {
    let session = self.get_session()?;
    Ok(session.user_id)
  }

  pub async fn is_local_mode(&self) -> FlowyResult<bool> {
    let session = self.get_session()?;
    let mut conn = self.get_sqlite_connection(session.user_id)?;
    let workspace_type = select_user_workspace_type(&session.workspace_id, &mut conn)?;
    Ok(matches!(workspace_type, AuthType::Local))
  }

  pub fn device_id(&self) -> FlowyResult<String> {
    Ok(self.user_config.device_id.to_string())
  }

  pub fn workspace_id(&self) -> FlowyResult<Uuid> {
    let session = self.get_session()?;
    let workspace_uuid = Uuid::from_str(&session.workspace_id)?;
    Ok(workspace_uuid)
  }

  pub fn workspace_database_object_id(&self) -> FlowyResult<Uuid> {
    let session = self.get_session()?;
    let mut conn = self.get_sqlite_connection(session.user_id)?;
    let workspace = select_user_workspace(&session.workspace_id, &mut conn)?;
    let id = Uuid::from_str(&workspace.database_storage_id)?;
    Ok(id)
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

  pub fn get_index_path(&self) -> FlowyResult<PathBuf> {
    let uid = self.user_id()?;
    Ok(PathBuf::from(self.user_paths.user_data_dir(uid)).join("indexes"))
  }

  pub fn get_user_data_dir(&self) -> FlowyResult<PathBuf> {
    let uid = self.user_id()?;
    Ok(PathBuf::from(self.user_paths.user_data_dir(uid)))
  }

  pub fn get_application_root_dir(&self) -> &str {
    self.user_paths.root()
  }

  pub fn close_db(&self) -> FlowyResult<()> {
    let session = self.get_session()?;
    info!("Close db for user: {}", session.user_id);
    self.database.close(session.user_id)?;
    Ok(())
  }

  pub fn is_collab_on_disk(&self, uid: i64, object_id: &str) -> FlowyResult<bool> {
    let session = self.get_session()?;
    let collab_db = self.database.get_collab_db(uid)?;
    let read_txn = collab_db.read_txn();
    Ok(read_txn.is_exist(uid, session.workspace_id.as_str(), object_id))
  }

  pub fn set_session(&self, session: Option<Arc<Session>>) -> Result<(), FlowyError> {
    match session {
      None => {
        let previous = self.session.swap(session);
        info!("remove session: {:?}", previous);
        self
          .store_preferences
          .remove(self.user_config.session_cache_key.as_ref());
      },
      Some(session) => {
        self.session.swap(Some(session.clone()));
        info!("Set current session: {:?}", session);
        self
          .store_preferences
          .set_object(&self.user_config.session_cache_key, &session)
          .map_err(internal_error)?;
      },
    }
    Ok(())
  }

  pub fn set_user_workspace(&self, user_workspace: UserWorkspace) -> FlowyResult<()> {
    let session = self.get_session()?;
    self.set_session(Some(Arc::new(Session {
      user_id: session.user_id,
      user_uuid: session.user_uuid,
      workspace_id: user_workspace.id,
    })))
  }

  pub fn get_session(&self) -> FlowyResult<Arc<Session>> {
    if let Some(session) = self.session.load_full() {
      return Ok(session);
    }

    match self
      .store_preferences
      .get_object::<Session>(&self.user_config.session_cache_key)
    {
      None => Err(FlowyError::new(
        ErrorCode::RecordNotFound,
        "Can't find user session. Please login again",
      )),
      Some(session) => {
        let session = Arc::new(session);
        self.session.store(Some(session.clone()));
        Ok(session)
      },
    }
  }
}
