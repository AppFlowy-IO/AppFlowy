use client_api::entity::GotrueTokenResponse;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_error::FlowyResult;
use std::str::FromStr;

use collab::lock::RwLock;
use collab_user::core::UserAwareness;
use dashmap::DashMap;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::schema::user_table;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{query_dsl::*, DBConnection, ExpressionMethods};
use flowy_user_pub::cloud::{UserCloudServiceProvider, UserUpdate};
use flowy_user_pub::entities::*;
use flowy_user_pub::workspace_service::UserWorkspaceService;
use lib_infra::box_any::BoxAny;
use semver::Version;
use serde_json::Value;
use std::string::ToString;
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Arc, Weak};
use tokio_stream::StreamExt;
use tracing::{debug, error, event, info, instrument, warn};
use uuid::Uuid;

use crate::entities::{AuthStateChangedPB, AuthStatePB, UserProfilePB, UserSettingPB};
use crate::event_map::{DefaultUserStatusCallback, UserStatusCallback};
use crate::migrations::document_empty_content::HistoricalEmptyDocumentMigration;
use crate::migrations::migration::{
  save_migration_record, UserDataMigration, UserLocalDataMigration, FIRST_TIME_INSTALL_VERSION,
};
use crate::migrations::workspace_and_favorite_v1::FavoriteV1AndWorkspaceArrayMigration;
use crate::migrations::workspace_trash_v1::WorkspaceTrashMapToSectionMigration;
use crate::services::authenticate_user::AuthenticateUser;
use crate::services::cloud_config::get_cloud_config;
use crate::services::collab_interact::{DefaultCollabInteract, UserReminder};

use crate::migrations::anon_user_workspace::AnonUserWorkspaceTableMigration;
use crate::migrations::doc_key_with_workspace::CollabDocKeyWithWorkspaceIdMigration;
use crate::{errors::FlowyError, notification::*};
use flowy_user_pub::session::Session;
use flowy_user_pub::sql::*;

pub struct UserManager {
  pub(crate) cloud_service: Weak<dyn UserCloudServiceProvider>,
  pub(crate) store_preferences: Arc<KVStorePreferences>,
  pub(crate) user_awareness_by_workspace: DashMap<Uuid, Arc<RwLock<UserAwareness>>>,
  pub(crate) user_status_callback: RwLock<Arc<dyn UserStatusCallback>>,
  pub(crate) collab_builder: Weak<AppFlowyCollabBuilder>,
  pub(crate) collab_interact: RwLock<Arc<dyn UserReminder>>,
  pub(crate) user_workspace_service: Arc<dyn UserWorkspaceService>,
  pub(crate) authenticate_user: Arc<AuthenticateUser>,
  refresh_user_profile_since: AtomicI64,
  pub(crate) is_loading_awareness: Arc<DashMap<Uuid, bool>>,
}

impl Drop for UserManager {
  fn drop(&mut self) {
    tracing::trace!("[Drop] drop user manager");
  }
}

impl UserManager {
  pub fn new(
    cloud_services: Weak<dyn UserCloudServiceProvider>,
    store_preferences: Arc<KVStorePreferences>,
    collab_builder: Weak<AppFlowyCollabBuilder>,
    authenticate_user: Arc<AuthenticateUser>,
    user_workspace_service: Arc<dyn UserWorkspaceService>,
  ) -> Arc<Self> {
    let user_status_callback: RwLock<Arc<dyn UserStatusCallback>> =
      RwLock::new(Arc::new(DefaultUserStatusCallback));

    let refresh_user_profile_since = AtomicI64::new(0);
    let user_manager = Arc::new(Self {
      cloud_service: cloud_services,
      store_preferences,
      user_awareness_by_workspace: Default::default(),
      user_status_callback,
      collab_builder,
      collab_interact: RwLock::new(Arc::new(DefaultCollabInteract)),
      authenticate_user,
      refresh_user_profile_since,
      user_workspace_service,
      is_loading_awareness: Arc::new(Default::default()),
    });

    let weak_user_manager = Arc::downgrade(&user_manager);
    if let Ok(user_service) = user_manager
      .cloud_service
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)
      .and_then(|v| v.get_user_service())
    {
      if let Some(mut rx) = user_service.subscribe_user_update() {
        tokio::spawn(async move {
          while let Some(update) = rx.recv().await {
            if let Some(user_manager) = weak_user_manager.upgrade() {
              if let Err(err) = user_manager.handler_user_update(update).await {
                error!("handler_user_update failed: {:?}", err);
              }
            }
          }
        });
      }
    }

    user_manager
  }

  pub fn cloud_service(&self) -> FlowyResult<Arc<dyn UserCloudServiceProvider>> {
    self
      .cloud_service
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)
  }

  pub fn close_db(&self) {
    if let Err(err) = self.authenticate_user.close_db() {
      error!("Close db failed: {:?}", err);
    }
  }

  pub fn get_store_preferences(&self) -> Weak<KVStorePreferences> {
    Arc::downgrade(&self.store_preferences)
  }

  /// Initializes the user session, including data migrations and user awareness configuration. This function
  /// will be invoked each time the user opens the application.
  ///
  /// Starts by retrieving the current session. If the session is successfully obtained, it will attempt
  /// a local data migration for the user. After ensuring the user's data is migrated and up-to-date,
  /// the function will set up the collaboration configuration and initialize the user's awareness. Upon successful
  /// completion, a user status callback is invoked to signify that the initialization process is complete.
  #[instrument(level = "debug", skip_all, err)]
  pub async fn init_with_callback<C: UserStatusCallback + 'static, I: UserReminder>(
    &self,
    user_status_callback: C,
    collab_interact: I,
  ) -> Result<(), FlowyError> {
    let user_status_callback = Arc::new(user_status_callback);
    *self.user_status_callback.write().await = user_status_callback.clone();
    *self.collab_interact.write().await = Arc::new(collab_interact);
    let cloud_service = self.cloud_service()?;

    if let Ok(session) = self.get_session() {
      info!(
        "Init user session: {}, workspace: {}",
        session.user_id, session.workspace_id
      );
      let workspace_uuid = Uuid::parse_str(&session.workspace_id)?;
      let mut conn = self.db_connection(session.user_id)?;
      let auth_type = select_user_workspace_type(&session.workspace_id, &mut conn)?;

      let uid = session.user_id;
      let token = self.token_from_auth_type(&auth_type)?;
      cloud_service.set_server_auth_type(&auth_type, token.clone())?;

      event!(
        tracing::Level::INFO,
        "init user session: {}, auth type: {:?}",
        uid,
        auth_type,
      );

      self.prepare_user(&session).await;
      self.prepare_backup(&session).await;

      // Set the token if the current cloud service using token to authenticate
      // Currently, only the AppFlowy cloud using token to init the client api.
      // TODO(nathan): using trait to separate the init process for different cloud service
      if auth_type.is_appflowy_cloud() {
        let local_token = token.unwrap_or_default();
        // Subscribe the token state
        let weak_cloud_services = self.cloud_service.clone();
        let weak_authenticate_user = Arc::downgrade(&self.authenticate_user);
        let weak_pool = Arc::downgrade(&self.db_pool(uid)?);
        let workspace_id = session.workspace_id.clone();
        let cloned_session = session.clone();
        if let Some(mut token_state_rx) = cloud_service.subscribe_token_state() {
          event!(tracing::Level::DEBUG, "Listen token state change");
          let user_uid = uid;
          tokio::spawn(async move {
            while let Some(token_state) = token_state_rx.next().await {
              debug!("Token state changed: {:?}", token_state);
              match token_state {
                UserTokenState::Refresh { token: new_token } => {
                  // Only save the token if the token is different from the current token
                  if new_token != local_token {
                    if let Some(conn) = weak_pool.upgrade().and_then(|pool| pool.get().ok()) {
                      // Save the new token
                      if let Err(err) = save_user_token(user_uid, &workspace_id, conn, new_token) {
                        error!("Save user token failed: {}", err);
                      }
                    }
                  }
                },
                UserTokenState::Invalid => {
                  // Attempt to upgrade the weak reference for cloud_services
                  let cloud_services = match weak_cloud_services.upgrade() {
                    Some(cloud_services) => cloud_services,
                    None => {
                      error!("Failed to upgrade weak reference for cloud_services");
                      return; // Exit early if the upgrade fails
                    },
                  };

                  // Attempt to upgrade the weak reference for authenticate_user
                  let authenticate_user = match weak_authenticate_user.upgrade() {
                    Some(authenticate_user) => authenticate_user,
                    None => {
                      warn!("Failed to upgrade weak reference for authenticate_user");
                      return; // Exit early if the upgrade fails
                    },
                  };

                  // Attempt to upgrade the weak reference for pool and then get a connection
                  let conn = match weak_pool.upgrade() {
                    Some(pool) => match pool.get() {
                      Ok(conn) => conn,
                      Err(_) => {
                        warn!("Failed to get connection from pool");
                        return; // Exit early if getting connection fails
                      },
                    },
                    None => {
                      warn!("Failed to upgrade weak reference for pool");
                      return; // Exit early if the upgrade fails
                    },
                  };

                  // If all upgrades succeed, proceed with the sign_out operation
                  if let Err(err) =
                    sign_out(&cloud_services, &cloned_session, &authenticate_user, conn).await
                  {
                    error!("Sign out when token invalid failed: {:?}", err);
                  }
                },
                UserTokenState::Init => {},
              }
            }
          });
        }
      }

      // Do the user data migration if needed.
      event!(tracing::Level::INFO, "Prepare user data migration");
      let mut conn = self.db_connection(uid)?;
      let user_auth_type = select_user_auth_type(uid, &mut conn)?;
      match (
        self
          .authenticate_user
          .database
          .get_collab_db(session.user_id),
        self.authenticate_user.database.get_pool(session.user_id),
      ) {
        (Ok(collab_db), Ok(sqlite_pool)) => {
          run_data_migration(
            &session,
            &user_auth_type,
            collab_db,
            sqlite_pool,
            self.store_preferences.clone(),
            &self.authenticate_user.user_config.app_version,
          );
        },
        _ => error!("Failed to get collab db or sqlite pool"),
      }

      // migrations should run before set the first time installed version
      self.set_first_time_installed_version();
      let cloud_config = get_cloud_config(session.user_id, &self.store_preferences);
      // Init the user awareness. here we ignore the error
      let _ = self
        .initial_user_awareness(
          session.user_id,
          &session.user_uuid,
          &workspace_uuid,
          &auth_type,
        )
        .await;

      user_status_callback
        .on_launch_if_authenticated(
          uid,
          &cloud_config,
          &workspace_uuid,
          &self.authenticate_user.user_config.device_id,
          &auth_type,
        )
        .await?;
    } else {
      self.set_first_time_installed_version();
    }
    Ok(())
  }

  fn set_first_time_installed_version(&self) {
    if self
      .store_preferences
      .get_str(FIRST_TIME_INSTALL_VERSION)
      .is_none()
    {
      info!(
        "Set install version: {:?}",
        self.authenticate_user.user_config.app_version
      );
      if let Err(err) = self.store_preferences.set_object(
        FIRST_TIME_INSTALL_VERSION,
        &self.authenticate_user.user_config.app_version,
      ) {
        error!("Set install version error: {:?}", err);
      }
    }
  }

  pub fn get_session(&self) -> FlowyResult<Arc<Session>> {
    self.authenticate_user.get_session()
  }

  pub fn db_connection(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self.authenticate_user.database.get_connection(uid)
  }

  pub fn db_pool(&self, uid: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
    self.authenticate_user.database.get_pool(uid)
  }

  pub fn get_collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self.authenticate_user.database.get_collab_db(uid)
  }

  #[cfg(debug_assertions)]
  pub fn get_collab_backup_list(&self, uid: i64) -> Vec<String> {
    self.authenticate_user.database.get_collab_backup_list(uid)
  }

  /// Performs a user sign-in, initializing user awareness and sending relevant notifications.
  ///
  /// This asynchronous function interacts with an external user service to authenticate and sign in a user
  /// based on provided parameters. Once signed in, it updates the collaboration configuration, logs the user,
  /// saves their workspaces, and initializes their user awareness.
  ///
  /// A sign-in notification is also sent after a successful sign-in.
  ///
  #[tracing::instrument(level = "info", skip(self, params))]
  pub async fn sign_in(
    &self,
    params: SignInParams,
    auth_type: AuthType,
  ) -> Result<UserProfile, FlowyError> {
    let cloud_service = self.cloud_service()?;
    cloud_service.set_server_auth_type(&auth_type, None)?;

    let response: AuthResponse = cloud_service
      .get_user_service()?
      .sign_in(BoxAny::new(params))
      .await?;
    let session = Session::from(&response);
    self.prepare_user(&session).await;

    let latest_workspace = response.latest_workspace.clone();
    let workspace_id = Uuid::parse_str(&latest_workspace.id)?;
    let user_profile = UserProfile::from((&response, &auth_type));
    self.save_auth_data(&response, auth_type, &session).await?;

    let _ = self
      .initial_user_awareness(
        session.user_id,
        &session.user_uuid,
        &workspace_id,
        &user_profile.workspace_auth_type,
      )
      .await;
    self
      .user_status_callback
      .read()
      .await
      .on_sign_in(
        user_profile.uid,
        &workspace_id,
        &self.authenticate_user.user_config.device_id,
        &auth_type,
      )
      .await?;
    send_auth_state_notification(AuthStateChangedPB {
      state: AuthStatePB::AuthStateSignIn,
      message: "Sign in success".to_string(),
    });
    Ok(user_profile)
  }

  /// Manages the user sign-up process, potentially migrating data if necessary.
  ///
  /// This asynchronous function interacts with an external authentication service to register and sign up a user
  /// based on the provided parameters. Following a successful sign-up, it handles configuration updates, logging,
  /// and saving workspace information. If a user is signing up with a new profile and previously had guest data,
  /// this function may migrate that data over to the new account.
  ///
  #[tracing::instrument(level = "info", skip(self, params))]
  pub async fn sign_up(
    &self,
    auth_type: AuthType,
    params: BoxAny,
  ) -> Result<UserProfile, FlowyError> {
    let cloud_service = self.cloud_service()?;
    cloud_service.set_server_auth_type(&auth_type, None)?;

    let auth_service = cloud_service.get_user_service()?;
    let response: AuthResponse = auth_service.sign_up(params).await?;
    let new_user_profile = UserProfile::from((&response, &auth_type));
    self
      .continue_sign_up(&new_user_profile, response, &auth_type)
      .await?;
    Ok(new_user_profile)
  }

  #[tracing::instrument(level = "info", skip_all, err)]
  async fn continue_sign_up(
    &self,
    new_user_profile: &UserProfile,
    response: AuthResponse,
    auth_type: &AuthType,
  ) -> FlowyResult<()> {
    let new_session = Session::from(&response);
    let workspace_id = Uuid::parse_str(&new_session.workspace_id)?;
    self.prepare_user(&new_session).await;
    self
      .save_auth_data(&response, *auth_type, &new_session)
      .await?;
    let _ = self
      .initial_user_awareness(
        new_session.user_id,
        &new_session.user_uuid,
        &workspace_id,
        auth_type,
      )
      .await;
    let workspace_id = Uuid::parse_str(&new_session.workspace_id)?;
    self
      .user_status_callback
      .read()
      .await
      .on_sign_up(
        response.is_new_user,
        new_user_profile,
        &workspace_id,
        &self.authenticate_user.user_config.device_id,
        auth_type,
      )
      .await?;

    if response.is_new_user {
      // For new user, we don't need to run the migrations
      if let Ok(pool) = self
        .authenticate_user
        .database
        .get_pool(new_session.user_id)
      {
        mark_all_migrations_as_applied(&pool);
      } else {
        error!("Failed to get pool for user {}", new_session.user_id);
      }
    }

    send_auth_state_notification(AuthStateChangedPB {
      state: AuthStatePB::AuthStateSignIn,
      message: "Sign up success".to_string(),
    });
    Ok(())
  }

  #[tracing::instrument(level = "info", skip(self))]
  pub async fn sign_out(&self) -> Result<(), FlowyError> {
    if let Ok(session) = self.get_session() {
      sign_out(
        &self.cloud_service()?,
        &session,
        &self.authenticate_user,
        self.db_connection(session.user_id)?,
      )
      .await?;
    }
    Ok(())
  }

  #[tracing::instrument(level = "info", skip(self))]
  pub async fn delete_account(&self) -> Result<(), FlowyError> {
    self
      .cloud_service()?
      .get_user_service()?
      .delete_account()
      .await?;
    Ok(())
  }

  /// Updates the user's profile with the given parameters.
  ///
  /// This function modifies the user's profile based on the provided update parameters. After updating, it
  /// sends a notification about the change. It's also responsible for handling interactions with the underlying
  /// database and updates user profile.
  ///
  #[tracing::instrument(level = "debug", skip(self))]
  pub async fn update_user_profile(
    &self,
    params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    let changeset = UserTableChangeset::new(params.clone());
    let session = self.get_session()?;
    upsert_user_profile_change(
      session.user_id,
      &session.workspace_id,
      self.db_connection(session.user_id)?,
      changeset,
    )?;
    self
      .cloud_service()?
      .get_user_service()?
      .update_user(params)
      .await?;

    Ok(())
  }

  pub async fn init_user(&self) -> Result<(), FlowyError> {
    Ok(())
  }

  pub async fn prepare_user(&self, session: &Session) {
    let _ = self.authenticate_user.database.close(session.user_id);
  }

  pub async fn prepare_backup(&self, session: &Session) {
    // Ensure to backup user data if a cloud drive is used for storage. While using a cloud drive
    // for storing user data is not advised due to potential data corruption risks, in scenarios where
    // users opt for cloud storage, the application should automatically create a backup of the user
    // data. This backup should be in the form of a zip file and stored locally on the user's disk
    // for safety and data integrity purposes
    self
      .authenticate_user
      .database
      .backup(session.user_id, &session.workspace_id);
  }

  /// Fetches the user profile for the given user ID.
  pub async fn get_user_profile_from_disk(
    &self,
    uid: i64,
    workspace_id: &str,
  ) -> Result<UserProfile, FlowyError> {
    let mut conn = self.db_connection(uid)?;
    select_user_profile(uid, workspace_id, &mut conn)
  }

  #[tracing::instrument(level = "info", skip_all, err)]
  pub async fn refresh_user_profile(
    &self,
    old_user_profile: &UserProfile,
    workspace_id: &str,
  ) -> FlowyResult<()> {
    // If the user is a local user, no need to refresh the user profile
    if old_user_profile.workspace_auth_type.is_local() {
      return Ok(());
    }

    let now = chrono::Utc::now().timestamp();
    // Add debounce to avoid too many requests
    if now - self.refresh_user_profile_since.load(Ordering::SeqCst) < 5 {
      return Ok(());
    }
    self.refresh_user_profile_since.store(now, Ordering::SeqCst);

    let uid = old_user_profile.uid;
    let result: Result<UserProfile, FlowyError> = self
      .cloud_service()?
      .get_user_service()?
      .get_user_profile(uid, workspace_id)
      .await;

    match result {
      Ok(new_user_profile) => {
        // If the user profile is updated, save the new user profile
        if new_user_profile.updated_at > old_user_profile.updated_at {
          // Save the new user profile
          let changeset = UserTableChangeset::from_user_profile(new_user_profile);
          let _ = upsert_user_profile_change(
            uid,
            workspace_id,
            self.authenticate_user.database.get_connection(uid)?,
            changeset,
          );
        }
        Ok(())
      },
      Err(err) => {
        if err.is_local_version_not_support() {
          return Ok(());
        }
        // If the user is not found, notify the frontend to logout
        if err.is_unauthorized() {
          event!(
            tracing::Level::ERROR,
            "User is unauthorized, sign out the user"
          );

          self.sign_out().await?;
          send_auth_state_notification(AuthStateChangedPB {
            state: AuthStatePB::InvalidAuth,
            message: "User is not found on the server".to_string(),
          });
        }
        Err(err)
      },
    }
  }

  #[instrument(level = "info", skip_all)]
  pub fn user_dir(&self, uid: i64) -> String {
    self.authenticate_user.user_paths.user_data_dir(uid)
  }

  pub fn token_from_auth_type(&self, auth_type: &AuthType) -> FlowyResult<Option<String>> {
    match auth_type {
      AuthType::Local => Ok(None),
      AuthType::AppFlowyCloud => {
        let uid = self.user_id()?;
        let mut conn = self.db_connection(uid)?;
        Ok(select_user_token(uid, &mut conn).ok())
      },
    }
  }
  pub fn user_setting(&self) -> Result<UserSettingPB, FlowyError> {
    let session = self.get_session()?;
    let user_setting = UserSettingPB {
      user_folder: self.user_dir(session.user_id),
    };
    Ok(user_setting)
  }

  pub fn user_id(&self) -> Result<i64, FlowyError> {
    Ok(self.get_session()?.user_id)
  }

  pub fn user_uuid(&self) -> Result<Uuid, FlowyError> {
    Ok(self.get_session()?.user_uuid)
  }

  pub fn workspace_id(&self) -> Result<Uuid, FlowyError> {
    let session = self.get_session()?;
    let uuid = Uuid::from_str(&session.workspace_id)?;
    Ok(uuid)
  }

  pub fn token(&self) -> Result<Option<String>, FlowyError> {
    Ok(None)
  }

  async fn save_user(&self, uid: i64, user: UserTable) -> Result<(), FlowyError> {
    let conn = self.db_connection(uid)?;
    upsert_user(user, conn)?;
    Ok(())
  }

  pub async fn receive_realtime_event(&self, json: Value) {
    if let Ok(user_service) = self.cloud_service().and_then(|v| v.get_user_service()) {
      user_service.receive_realtime_event(json)
    }
  }

  #[instrument(level = "info", skip_all)]
  pub(crate) async fn generate_sign_in_url_with_email(
    &self,
    authenticator: &AuthType,
    email: &str,
  ) -> Result<String, FlowyError> {
    let cloud_service = self.cloud_service()?;
    cloud_service.set_server_auth_type(authenticator, None)?;

    let auth_service = cloud_service.get_user_service()?;
    let url = auth_service.generate_sign_in_url_with_email(email).await?;
    Ok(url)
  }

  #[instrument(level = "info", skip_all)]
  pub(crate) async fn sign_in_with_password(
    &self,
    email: &str,
    password: &str,
  ) -> Result<GotrueTokenResponse, FlowyError> {
    self
      .cloud_service()?
      .set_server_auth_type(&AuthType::AppFlowyCloud, None)?;
    let auth_service = self.cloud_service()?.get_user_service()?;
    let response = auth_service.sign_in_with_password(email, password).await?;
    Ok(response)
  }

  #[instrument(level = "info", skip_all)]
  pub(crate) async fn sign_in_with_magic_link(
    &self,
    email: &str,
    redirect_to: &str,
  ) -> Result<(), FlowyError> {
    self
      .cloud_service()?
      .set_server_auth_type(&AuthType::AppFlowyCloud, None)?;
    let auth_service = self.cloud_service()?.get_user_service()?;
    auth_service
      .sign_in_with_magic_link(email, redirect_to)
      .await?;
    Ok(())
  }

  #[instrument(level = "info", skip_all)]
  pub(crate) async fn sign_in_with_passcode(
    &self,
    email: &str,
    passcode: &str,
  ) -> Result<GotrueTokenResponse, FlowyError> {
    self
      .cloud_service()?
      .set_server_auth_type(&AuthType::AppFlowyCloud, None)?;
    let auth_service = self.cloud_service()?.get_user_service()?;
    let response = auth_service.sign_in_with_passcode(email, passcode).await?;
    Ok(response)
  }

  #[instrument(level = "info", skip_all)]
  pub(crate) async fn generate_oauth_url(
    &self,
    oauth_provider: &str,
  ) -> Result<String, FlowyError> {
    self
      .cloud_service()?
      .set_server_auth_type(&AuthType::AppFlowyCloud, None)?;
    let auth_service = self.cloud_service()?.get_user_service()?;
    let url = auth_service
      .generate_oauth_url_with_provider(oauth_provider)
      .await?;
    Ok(url)
  }

  #[instrument(level = "info", skip_all, err)]
  async fn save_auth_data(
    &self,
    response: &impl UserAuthResponse,
    auth_type: AuthType,
    session: &Session,
  ) -> Result<(), FlowyError> {
    let user_profile = UserProfile::from((response, &auth_type));
    let uid = user_profile.uid;

    if auth_type.is_local() {
      event!(tracing::Level::DEBUG, "Save new anon user: {:?}", uid);
      self.set_anon_user(session);
    }

    let mut conn = self.db_connection(uid)?;
    sync_user_workspaces_with_diff(uid, auth_type, response.user_workspaces(), &mut conn)?;
    info!(
      "Save new user profile to disk, authenticator: {:?}",
      auth_type
    );

    self
      .authenticate_user
      .set_session(Some(session.clone().into()))?;
    self
      .save_user(uid, (user_profile, auth_type).into())
      .await?;
    Ok(())
  }

  async fn handler_user_update(&self, user_update: UserUpdate) -> FlowyResult<()> {
    let session = self.get_session()?;
    if session.user_id == user_update.uid {
      debug!("Receive user update: {:?}", user_update);
      // Save the user profile change
      upsert_user_profile_change(
        user_update.uid,
        &session.workspace_id,
        self.db_connection(user_update.uid)?,
        UserTableChangeset::from(user_update),
      )?;
    }

    Ok(())
  }
}

pub fn upsert_user_profile_change(
  uid: i64,
  workspace_id: &str,
  mut conn: DBConnection,
  changeset: UserTableChangeset,
) -> FlowyResult<()> {
  event!(
    tracing::Level::DEBUG,
    "Update user profile with changeset: {:?}",
    changeset
  );
  update_user_profile(&mut conn, changeset)?;
  let user = select_user_profile(uid, workspace_id, &mut conn)?;
  send_notification(&uid.to_string(), UserNotification::DidUpdateUserProfile)
    .payload(UserProfilePB::from(user))
    .send();
  Ok(())
}

#[instrument(level = "info", skip_all, err)]
fn save_user_token(
  uid: i64,
  workspace_id: &str,
  conn: DBConnection,
  token: String,
) -> FlowyResult<()> {
  let params = UpdateUserProfileParams::new(uid).with_token(token);
  let changeset = UserTableChangeset::new(params);
  upsert_user_profile_change(uid, workspace_id, conn, changeset)
}

#[instrument(level = "info", skip_all, err)]
fn remove_user_token(uid: i64, mut conn: DBConnection) -> FlowyResult<()> {
  diesel::update(user_table::dsl::user_table.filter(user_table::id.eq(&uid.to_string())))
    .set(user_table::token.eq(""))
    .execute(&mut *conn)?;
  Ok(())
}

fn collab_migration_list() -> Vec<Box<dyn UserDataMigration>> {
  // ⚠️The order of migrations is crucial. If you're adding a new migration, please ensure
  // it's appended to the end of the list.
  vec![
    Box::new(HistoricalEmptyDocumentMigration),
    Box::new(FavoriteV1AndWorkspaceArrayMigration),
    Box::new(WorkspaceTrashMapToSectionMigration),
    Box::new(CollabDocKeyWithWorkspaceIdMigration),
    Box::new(AnonUserWorkspaceTableMigration),
  ]
}

fn mark_all_migrations_as_applied(sqlite_pool: &Arc<ConnectionPool>) {
  if let Ok(mut conn) = sqlite_pool.get() {
    for migration in collab_migration_list() {
      save_migration_record(&mut conn, migration.name());
    }
    info!("Mark all migrations as applied");
  }
}

pub(crate) fn run_data_migration(
  session: &Session,
  user_auth_type: &AuthType,
  collab_db: Weak<CollabKVDB>,
  sqlite_pool: Arc<ConnectionPool>,
  kv: Arc<KVStorePreferences>,
  app_version: &Version,
) {
  let migrations = collab_migration_list();
  match UserLocalDataMigration::new(session.clone(), collab_db, sqlite_pool, kv).run(
    migrations,
    user_auth_type,
    app_version,
  ) {
    Ok(applied_migrations) => {
      if !applied_migrations.is_empty() {
        info!(
          "[Migration]: did apply migrations: {:?}",
          applied_migrations
        );
      }
    },
    Err(e) => error!("[AppflowyData]:User data migration failed: {:?}", e),
  }
}

#[instrument(level = "info", skip_all, err)]
pub async fn sign_out(
  cloud_services: &Arc<dyn UserCloudServiceProvider>,
  session: &Session,
  authenticate_user: &AuthenticateUser,
  conn: DBConnection,
) -> Result<(), FlowyError> {
  info!("[Sign out] Sign out user: {}", session.user_id);
  let _ = remove_user_token(session.user_id, conn);

  info!(
    "[Sign out] Close user related database: {}",
    session.user_id
  );
  authenticate_user.database.close(session.user_id)?;
  authenticate_user.set_session(None)?;

  let server = cloud_services.get_user_service()?;
  if let Err(err) = server.sign_out(None).await {
    event!(tracing::Level::ERROR, "{:?}", err);
  }

  Ok(())
}
