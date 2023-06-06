use std::sync::Arc;

use appflowy_integrate::RocksCollabDB;
use serde::{Deserialize, Serialize};
use serde_repr::*;
use tokio::sync::RwLock;

use flowy_error::internal_error;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{
  kv::KV,
  query_dsl::*,
  schema::{user_table, user_table::dsl},
  DBConnection, ExpressionMethods, UserDatabaseConnection,
};
use lib_infra::box_any::BoxAny;

use crate::entities::{
  AuthTypePB, SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile,
};
use crate::entities::{UserProfilePB, UserSettingPB};
use crate::event_map::{DefaultUserStatusCallback, UserCloudServiceProvider, UserStatusCallback};
use crate::{
  errors::FlowyError,
  event_map::UserAuthService,
  notification::*,
  services::database::{UserDB, UserTable, UserTableChangeset},
};

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
      let _ = user_status_callback
        .did_sign_in(session.user_id, &session.workspace_id)
        .await;
    }
    *self.user_status_callback.write().await = Arc::new(user_status_callback);
  }

  pub fn db_connection(&self) -> Result<DBConnection, FlowyError> {
    let user_id = self.get_session()?.user_id;
    self.database.get_connection(user_id)
  }

  // The caller will be not 'Sync' before of the return value,
  // PooledConnection<ConnectionManager> is not sync. You can use
  // db_connection_pool function to require the ConnectionPool that is 'Sync'.
  //
  // let pool = self.db_connection_pool()?;
  // let conn: PooledConnection<ConnectionManager> = pool.get()?;
  pub fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
    let user_id = self.get_session()?.user_id;
    self.database.get_pool(user_id)
  }

  pub fn get_collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError> {
    let user_id = self.get_session()?.user_id;
    self.database.get_collab_db(user_id)
  }

  #[tracing::instrument(level = "debug", skip(self, params))]
  pub async fn sign_in(
    &self,
    auth_type: &AuthType,
    params: BoxAny,
  ) -> Result<UserProfile, FlowyError> {
    self
      .user_status_callback
      .read()
      .await
      .auth_type_did_changed(auth_type.clone());

    self.cloud_services.set_auth_type(auth_type.clone());
    let resp = self
      .cloud_services
      .get_auth_service()?
      .sign_in(params)
      .await?;

    let session: Session = resp.clone().into();
    self.set_session(Some(session))?;
    let user_profile: UserProfile = self.save_user(resp.into()).await?.into();
    let _ = self
      .user_status_callback
      .read()
      .await
      .did_sign_in(user_profile.id, &user_profile.workspace_id)
      .await;
    send_sign_in_notification()
      .payload::<UserProfilePB>(user_profile.clone().into())
      .send();

    Ok(user_profile)
  }

  #[tracing::instrument(level = "debug", skip(self, params))]
  pub async fn sign_up(
    &self,
    auth_type: &AuthType,
    params: BoxAny,
  ) -> Result<UserProfile, FlowyError> {
    self
      .user_status_callback
      .read()
      .await
      .auth_type_did_changed(auth_type.clone());

    self.cloud_services.set_auth_type(auth_type.clone());
    let resp = self
      .cloud_services
      .get_auth_service()?
      .sign_up(params)
      .await?;

    let session: Session = resp.clone().into();
    self.set_session(Some(session))?;
    let user_table = self.save_user(resp.into()).await?;
    let user_profile: UserProfile = user_table.into();
    let _ = self
      .user_status_callback
      .read()
      .await
      .did_sign_up(&user_profile)
      .await;
    Ok(user_profile)
  }

  #[tracing::instrument(level = "debug", skip(self))]
  pub async fn sign_out(&self, auth_type: &AuthType) -> Result<(), FlowyError> {
    let session = self.get_session()?;
    let uid = session.user_id.to_string();
    let _ = diesel::delete(dsl::user_table.filter(dsl::id.eq(&uid)))
      .execute(&*(self.db_connection()?))?;
    self.database.close_user_db(session.user_id)?;
    self.set_session(None)?;

    let server = self.cloud_services.get_auth_service()?;
    let token = session.token;
    let _ = tokio::spawn(async move {
      match server.sign_out(token).await {
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
    diesel_update_table!(user_table, changeset, &*self.db_connection()?);

    let user_profile = self.get_user_profile().await?;
    let profile_pb: UserProfilePB = user_profile.into();
    send_notification(
      &session.user_id.to_string(),
      UserNotification::DidUpdateUserProfile,
    )
    .payload(profile_pb)
    .send();
    self
      .update_user(&auth_type, session.user_id, &session.token, params)
      .await?;
    Ok(())
  }

  pub async fn init_user(&self) -> Result<(), FlowyError> {
    Ok(())
  }

  pub async fn check_user(&self) -> Result<UserProfile, FlowyError> {
    let (user_id, _token) = self.get_session()?.into_part();
    let user_id = user_id.to_string();
    let user = dsl::user_table
      .filter(user_table::id.eq(&user_id))
      .first::<UserTable>(&*(self.db_connection()?))?;
    Ok(user.into())
  }

  pub async fn get_user_profile(&self) -> Result<UserProfile, FlowyError> {
    let (user_id, _) = self.get_session()?.into_part();
    let user_id = user_id.to_string();
    let user = dsl::user_table
      .filter(user_table::id.eq(&user_id))
      .first::<UserTable>(&*(self.db_connection()?))?;

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

  pub fn user_name(&self) -> Result<String, FlowyError> {
    Ok(self.get_session()?.name)
  }

  pub fn token(&self) -> Result<Option<String>, FlowyError> {
    Ok(self.get_session()?.token)
  }
}

impl UserSession {
  async fn update_user(
    &self,
    _auth_type: &AuthType,
    uid: i64,
    token: &Option<String>,
    params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    let server = self.cloud_services.get_auth_service()?;
    let token = token.to_owned();
    let _ = tokio::spawn(async move {
      match server.update_user(uid, &token, params).await {
        Ok(_) => {},
        Err(e) => {
          // TODO: retry?
          tracing::error!("update user profile failed: {:?}", e);
        },
      }
    })
    .await;
    Ok(())
  }

  async fn save_user(&self, user: UserTable) -> Result<UserTable, FlowyError> {
    let conn = self.db_connection()?;
    let _ = diesel::insert_into(user_table::table)
      .values(user.clone())
      .execute(&*conn)?;
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

  fn get_session(&self) -> Result<Session, FlowyError> {
    match KV::get_object::<Session>(&self.session_config.session_cache_key) {
      None => Err(FlowyError::unauthorized()),
      Some(session) => Ok(session),
    }
  }
}

pub async fn update_user(
  _cloud_service: Arc<dyn UserAuthService>,
  pool: Arc<ConnectionPool>,
  params: UpdateUserProfileParams,
) -> Result<(), FlowyError> {
  let changeset = UserTableChangeset::new(params);
  let conn = pool.get()?;
  diesel_update_table!(user_table, changeset, &*conn);
  Ok(())
}

impl UserDatabaseConnection for UserSession {
  fn get_connection(&self) -> Result<DBConnection, String> {
    self.db_connection().map_err(|e| format!("{:?}", e))
  }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
struct Session {
  user_id: i64,

  workspace_id: String,

  #[serde(default)]
  name: String,

  #[serde(default)]
  token: Option<String>,

  #[serde(default)]
  email: Option<String>,
}

impl std::convert::From<SignInResponse> for Session {
  fn from(resp: SignInResponse) -> Self {
    Session {
      user_id: resp.user_id,
      token: resp.token,
      email: resp.email,
      name: resp.name,
      workspace_id: resp.workspace_id,
    }
  }
}

impl std::convert::From<SignUpResponse> for Session {
  fn from(resp: SignUpResponse) -> Self {
    Session {
      user_id: resp.user_id,
      token: resp.token,
      email: resp.email,
      name: resp.name,
      workspace_id: resp.workspace_id,
    }
  }
}

impl Session {
  pub fn into_part(self) -> (i64, Option<String>) {
    (self.user_id, self.token)
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
