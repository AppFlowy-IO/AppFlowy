use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;
use collab_folder::core::FolderData;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use tokio::sync::RwLock;
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{
  kv::KV,
  query_dsl::*,
  schema::{user_table, user_table::dsl},
  DBConnection, ExpressionMethods,
};
use lib_infra::box_any::BoxAny;

use crate::entities::{
  AuthTypePB, SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile,
};
use crate::entities::{UserProfilePB, UserSettingPB};
use crate::event_map::{
  DefaultUserStatusCallback, SignUpContext, UserCloudServiceProvider, UserCredentials,
  UserStatusCallback,
};
use crate::services::user_data::UserDataMigration;
use crate::{
  errors::FlowyError,
  notification::*,
  services::database::{UserDB, UserTable, UserTableChangeset},
};

pub(crate) const SUPABASE_CONFIG_CACHE_KEY: &str = "supabase_config_cache_key";
pub struct UserSessionConfig {
  root_dir: String,

  /// Used as the key of `Session` when saving session information to KV.
  session_cache_key: String,
}

impl UserSessionConfig {
  /// The `root_dir` represents as the root of the user folders. It must be unique for each
  /// users.
  pub fn new(name: &str, root_dir: &str) -> Self {
    let session_cache_key = format!("{}_session_cache", name);
    Self {
      root_dir: root_dir.to_owned(),
      session_cache_key,
    }
  }
}

pub struct UserSession {
  database: UserDB,
  session_config: UserSessionConfig,
  cloud_services: Arc<dyn UserCloudServiceProvider>,
  user_status_callback: RwLock<Arc<dyn UserStatusCallback>>,
}

impl UserSession {
  pub fn new(
    session_config: UserSessionConfig,
    cloud_services: Arc<dyn UserCloudServiceProvider>,
  ) -> Self {
    let db = UserDB::new(&session_config.root_dir);
    let user_status_callback: RwLock<Arc<dyn UserStatusCallback>> =
      RwLock::new(Arc::new(DefaultUserStatusCallback));
    Self {
      database: db,
      session_config,
      cloud_services,
      user_status_callback,
    }
  }

  pub async fn init<C: UserStatusCallback + 'static>(&self, user_status_callback: C) {
    if let Ok(session) = self.get_session() {
      if let Err(e) = user_status_callback
        .did_init(session.user_id, &session.workspace_id)
        .await
      {
        tracing::error!("Failed to call did_sign_in callback: {:?}", e);
      }
    }
    *self.user_status_callback.write().await = Arc::new(user_status_callback);
  }

  pub fn db_connection(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self.database.get_connection(uid)
  }

  // The caller will be not 'Sync' before of the return value,
  // PooledConnection<ConnectionManager> is not sync. You can use
  // db_connection_pool function to require the ConnectionPool that is 'Sync'.
  //
  // let pool = self.db_connection_pool()?;
  // let conn: PooledConnection<ConnectionManager> = pool.get()?;
  pub fn db_pool(&self, uid: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
    self.database.get_pool(uid)
  }

  pub fn get_collab_db(&self, uid: i64) -> Result<Arc<RocksCollabDB>, FlowyError> {
    self.database.get_collab_db(uid)
  }

  pub async fn migrate_old_user_data(
    &self,
    old_uid: i64,
    old_workspace_id: &str,
    new_uid: i64,
    new_workspace_id: &str,
  ) -> Result<Option<FolderData>, FlowyError> {
    let old_collab_db = self.database.get_collab_db(old_uid)?;
    let new_collab_db = self.database.get_collab_db(new_uid)?;
    let folder_data = UserDataMigration::migration(
      old_uid,
      &old_collab_db,
      old_workspace_id,
      new_uid,
      &new_collab_db,
      new_workspace_id,
    )?;
    Ok(folder_data)
  }

  pub fn clear_old_user(&self, old_uid: i64) {
    let _ = self.database.close(old_uid);
  }

  #[tracing::instrument(level = "debug", skip(self, params))]
  pub async fn sign_in(
    &self,
    params: BoxAny,
    auth_type: AuthType,
  ) -> Result<UserProfile, FlowyError> {
    let resp = self
      .cloud_services
      .get_auth_service()?
      .sign_in(params)
      .await?;

    let session: Session = resp.clone().into();
    let uid = session.user_id;
    self.set_session(Some(session))?;
    let user_profile: UserProfile = self.save_user(uid, (resp, auth_type).into()).await?.into();
    if let Err(e) = self
      .user_status_callback
      .read()
      .await
      .did_sign_in(user_profile.id, &user_profile.workspace_id)
      .await
    {
      tracing::error!("Failed to call did_sign_in callback: {:?}", e);
    }
    send_sign_in_notification()
      .payload::<UserProfilePB>(user_profile.clone().into())
      .send();

    Ok(user_profile)
  }

  pub async fn update_auth_type(&self, auth_type: &AuthType) {
    self
      .user_status_callback
      .read()
      .await
      .auth_type_did_changed(auth_type.clone());

    self.cloud_services.set_auth_type(auth_type.clone());
  }

  #[tracing::instrument(level = "debug", skip(self, params))]
  pub async fn sign_up(
    &self,
    auth_type: AuthType,
    params: BoxAny,
  ) -> Result<UserProfile, FlowyError> {
    let old_user_profile = {
      if let Ok(old_session) = self.get_session() {
        self.get_user_profile(old_session.user_id, false).await.ok()
      } else {
        None
      }
    };

    let auth_service = self.cloud_services.get_auth_service()?;
    let response: SignUpResponse = auth_service.sign_up(params).await?;
    let mut sign_up_context = SignUpContext {
      is_new: response.is_new,
      local_folder: None,
    };
    let session = Session {
      user_id: response.user_id,
      workspace_id: response.workspace_id.clone(),
    };
    let uid = session.user_id;
    self.set_session(Some(session))?;
    let user_table = self
      .save_user(uid, (response, auth_type.clone()).into())
      .await?;
    let new_user_profile: UserProfile = user_table.into();

    // Only migrate the data if the user is login in as a guest and sign up as a new user
    if sign_up_context.is_new {
      if let Some(old_user_profile) = old_user_profile {
        if old_user_profile.auth_type == AuthType::Local && !auth_type.is_local() {
          tracing::info!(
            "Migrate old user data from {:?} to {:?}",
            old_user_profile.id,
            new_user_profile.id
          );
          match self
            .migrate_old_user_data(
              old_user_profile.id,
              &old_user_profile.workspace_id,
              new_user_profile.id,
              &new_user_profile.workspace_id,
            )
            .await
          {
            Ok(folder_data) => sign_up_context.local_folder = folder_data,
            Err(e) => tracing::error!("{:?}", e),
          }
        }
      }
    }

    let _ = self
      .user_status_callback
      .read()
      .await
      .did_sign_up(sign_up_context, &new_user_profile)
      .await;
    Ok(new_user_profile)
  }

  #[tracing::instrument(level = "debug", skip(self))]
  pub async fn sign_out(&self) -> Result<(), FlowyError> {
    let session = self.get_session()?;
    self.database.close(session.user_id)?;
    self.set_session(None)?;

    let server = self.cloud_services.get_auth_service()?;
    tokio::spawn(async move {
      match server.sign_out(None).await {
        Ok(_) => {},
        Err(e) => tracing::error!("Sign out failed: {:?}", e),
      }
    });
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip(self))]
  pub async fn update_user_profile(
    &self,
    params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    let auth_type = params.auth_type.clone();
    let session = self.get_session()?;
    let changeset = UserTableChangeset::new(params.clone());
    diesel_update_table!(
      user_table,
      changeset,
      &*self.db_connection(session.user_id)?
    );

    let session = self.get_session()?;
    let user_profile = self.get_user_profile(session.user_id, false).await?;
    let profile_pb: UserProfilePB = user_profile.into();
    send_notification(
      &session.user_id.to_string(),
      UserNotification::DidUpdateUserProfile,
    )
    .payload(profile_pb)
    .send();
    self
      .update_user(&auth_type, session.user_id, None, params)
      .await?;
    Ok(())
  }

  pub async fn init_user(&self) -> Result<(), FlowyError> {
    Ok(())
  }

  pub async fn check_user(&self) -> Result<(), FlowyError> {
    let user_id = self.get_session()?.user_id;
    let credential = UserCredentials::from_uid(user_id);
    let auth_service = self.cloud_services.get_auth_service()?;
    auth_service.check_user(credential).await
  }

  pub async fn check_user_with_uuid(&self, uuid: &Uuid) -> Result<(), FlowyError> {
    let credential = UserCredentials::from_uuid(uuid.to_string());
    let auth_service = self.cloud_services.get_auth_service()?;
    auth_service.check_user(credential).await
  }

  /// Get the user profile from the database
  /// If the refresh is true, it will try to get the user profile from the server
  pub async fn get_user_profile(&self, uid: i64, refresh: bool) -> Result<UserProfile, FlowyError> {
    let user_id = uid.to_string();
    let user = dsl::user_table
      .filter(user_table::id.eq(&user_id))
      .first::<UserTable>(&*(self.db_connection(uid)?))?;

    if refresh {
      let weak_auth_service = Arc::downgrade(&self.cloud_services.get_auth_service()?);
      let weak_pool = Arc::downgrade(&self.database.get_pool(uid)?);
      tokio::spawn(async move {
        if let (Some(auth_service), Some(pool)) = (weak_auth_service.upgrade(), weak_pool.upgrade())
        {
          if let Ok(Some(user_profile)) = auth_service
            .get_user_profile(UserCredentials::from_uid(uid))
            .await
          {
            let changeset = UserTableChangeset::from_user_profile(user_profile.clone());
            if let Ok(conn) = pool.get() {
              let filter = dsl::user_table.filter(dsl::id.eq(changeset.id.clone()));
              let _ = diesel::update(filter).set(changeset).execute(&*conn);

              // Send notification to the client
              let user_profile_pb: UserProfilePB = user_profile.into();
              send_notification(&uid.to_string(), UserNotification::DidUpdateUserProfile)
                .payload(user_profile_pb)
                .send();
            }
          }
        }
      });
    }

    Ok(user.into())
  }

  pub fn user_dir(&self) -> Result<String, FlowyError> {
    let session = self.get_session()?;
    Ok(format!(
      "{}/{}",
      self.session_config.root_dir, session.user_id
    ))
  }

  pub fn user_setting(&self) -> Result<UserSettingPB, FlowyError> {
    let user_setting = UserSettingPB {
      user_folder: self.user_dir()?,
    };
    Ok(user_setting)
  }

  pub fn user_id(&self) -> Result<i64, FlowyError> {
    Ok(self.get_session()?.user_id)
  }

  pub fn token(&self) -> Result<Option<String>, FlowyError> {
    Ok(None)
  }

  pub fn save_supabase_config(&self, config: SupabaseConfiguration) {
    self.cloud_services.update_supabase_config(&config);
    let _ = KV::set_object(SUPABASE_CONFIG_CACHE_KEY, config);
  }
}

pub fn get_supabase_config() -> Option<SupabaseConfiguration> {
  KV::get_str(SUPABASE_CONFIG_CACHE_KEY)
    .and_then(|s| serde_json::from_str(&s).ok())
    .unwrap_or_else(|| SupabaseConfiguration::from_env().ok())
}

impl UserSession {
  async fn update_user(
    &self,
    _auth_type: &AuthType,
    uid: i64,
    token: Option<String>,
    params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    let server = self.cloud_services.get_auth_service()?;
    let token = token.to_owned();
    let _ = tokio::spawn(async move {
      let credentials = UserCredentials::new(token, Some(uid), None);
      match server.update_user(credentials, params).await {
        Ok(_) => {},
        Err(e) => {
          tracing::error!("update user profile failed: {:?}", e);
        },
      }
    })
    .await;
    Ok(())
  }

  async fn save_user(&self, uid: i64, user: UserTable) -> Result<UserTable, FlowyError> {
    let conn = self.db_connection(uid)?;
    conn.immediate_transaction(|| {
      // delete old user if exists
      diesel::delete(dsl::user_table.filter(dsl::id.eq(&user.id))).execute(&*conn)?;

      let _ = diesel::insert_into(user_table::table)
        .values(user.clone())
        .execute(&*conn)?;
      Ok::<(), FlowyError>(())
    })?;

    Ok(user)
  }

  fn set_session(&self, session: Option<Session>) -> Result<(), FlowyError> {
    tracing::debug!("Set user session: {:?}", session);
    match &session {
      None => KV::remove(&self.session_config.session_cache_key),
      Some(session) => {
        KV::set_object(&self.session_config.session_cache_key, session.clone())
          .map_err(internal_error)?;
      },
    }
    Ok(())
  }

  /// Returns the current user session.
  pub fn get_session(&self) -> Result<Session, FlowyError> {
    match KV::get_object::<Session>(&self.session_config.session_cache_key) {
      None => Err(FlowyError::new(
        ErrorCode::RecordNotFound,
        "User is not logged in".to_string(),
      )),
      Some(session) => Ok(session),
    }
  }

  pub fn sign_in_history(&self) -> Vec<UserProfile> {
    // match self.db_connection(uid) {
    //   Ok(conn) => match dsl::user_table.load::<UserTable>(&*conn) {
    //     Ok(users) => users.into_iter().map(|u| u.into()).collect(),
    //     Err(_) => vec![],
    //   },
    //   Err(e) => {
    //     tracing::error!("get user sign in history failed: {:?}", e);
    //     vec![]
    //   },
    // }
    vec![]
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Session {
  pub user_id: i64,
  pub workspace_id: String,
}

impl std::convert::From<SignInResponse> for Session {
  fn from(resp: SignInResponse) -> Self {
    Session {
      user_id: resp.user_id,
      workspace_id: resp.workspace_id,
    }
  }
}

impl std::convert::From<String> for Session {
  fn from(s: String) -> Self {
    match serde_json::from_str(&s) {
      Ok(s) => s,
      Err(e) => {
        tracing::error!("Deserialize string to Session failed: {:?}", e);
        Session::default()
      },
    }
  }
}
impl std::convert::From<Session> for String {
  fn from(session: Session) -> Self {
    match serde_json::to_string(&session) {
      Ok(s) => s,
      Err(e) => {
        tracing::error!("Serialize session to string failed: {:?}", e);
        "".to_string()
      },
    }
  }
}

#[derive(Debug, Clone, Hash, Serialize_repr, Deserialize_repr, Eq, PartialEq)]
#[repr(u8)]
pub enum AuthType {
  /// It's a local server, we do fake sign in default.
  Local = 0,
  /// Currently not supported. It will be supported in the future when the
  /// [AppFlowy-Server](https://github.com/AppFlowy-IO/AppFlowy-Server) ready.
  SelfHosted = 1,
  /// It uses Supabase as the backend.
  Supabase = 2,
}

impl AuthType {
  pub fn is_local(&self) -> bool {
    matches!(self, AuthType::Local)
  }
}

impl Default for AuthType {
  fn default() -> Self {
    Self::Local
  }
}

impl From<AuthTypePB> for AuthType {
  fn from(pb: AuthTypePB) -> Self {
    match pb {
      AuthTypePB::Supabase => AuthType::Supabase,
      AuthTypePB::Local => AuthType::Local,
      AuthTypePB::SelfHosted => AuthType::SelfHosted,
    }
  }
}

impl From<AuthType> for AuthTypePB {
  fn from(auth_type: AuthType) -> Self {
    match auth_type {
      AuthType::Supabase => AuthTypePB::Supabase,
      AuthType::Local => AuthTypePB::Local,
      AuthType::SelfHosted => AuthTypePB::SelfHosted,
    }
  }
}

impl From<i32> for AuthType {
  fn from(value: i32) -> Self {
    match value {
      0 => AuthType::Local,
      1 => AuthType::SelfHosted,
      2 => AuthType::Supabase,
      _ => AuthType::Local,
    }
  }
}

pub struct ThirdPartyParams {
  pub uuid: Uuid,
  pub email: String,
}

pub fn uuid_from_box_any(any: BoxAny) -> Result<ThirdPartyParams, FlowyError> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let uuid = uuid_from_map(&map)?;
  let email = map.get("email").cloned().unwrap_or_default();
  Ok(ThirdPartyParams { uuid, email })
}

pub fn uuid_from_map(map: &HashMap<String, String>) -> Result<Uuid, FlowyError> {
  let uuid = map
    .get("uuid")
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing uuid field"))?
    .as_str();
  Uuid::from_str(uuid).map_err(internal_error)
}
