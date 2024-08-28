use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_error::{internal_error, ErrorCode, FlowyResult};

use arc_swap::ArcSwapOption;
use collab_user::core::UserAwareness;
use dashmap::DashMap;
use flowy_server_pub::AuthenticatorType;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_sqlite::schema::user_table;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{query_dsl::*, DBConnection, ExpressionMethods};
use flowy_user_pub::cloud::{UserCloudServiceProvider, UserUpdate};
use flowy_user_pub::entities::*;
use flowy_user_pub::workspace_service::UserWorkspaceService;
use semver::Version;
use serde_json::Value;
use std::string::ToString;
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Arc, Weak};
use tokio::sync::{Mutex, RwLock};
use tokio_stream::StreamExt;
use tracing::{debug, error, event, info, instrument, trace, warn};

use lib_dispatch::prelude::af_spawn;
use lib_infra::box_any::BoxAny;

use crate::entities::{AuthStateChangedPB, AuthStatePB, UserProfilePB, UserSettingPB};
use crate::event_map::{DefaultUserStatusCallback, UserStatusCallback};
use crate::migrations::document_empty_content::HistoricalEmptyDocumentMigration;
use crate::migrations::migration::{
  save_migration_record, UserDataMigration, UserLocalDataMigration,
};
use crate::migrations::workspace_and_favorite_v1::FavoriteV1AndWorkspaceArrayMigration;
use crate::migrations::workspace_trash_v1::WorkspaceTrashMapToSectionMigration;
use crate::migrations::AnonUser;
use crate::services::authenticate_user::AuthenticateUser;
use crate::services::cloud_config::get_cloud_config;
use crate::services::collab_interact::{CollabInteract, DefaultCollabInteract};

use crate::services::sqlite_sql::user_sql::{select_user_profile, UserTable, UserTableChangeset};
use crate::user_manager::manager_user_encryption::validate_encryption_sign;
use crate::user_manager::manager_user_workspace::save_all_user_workspaces;
use crate::user_manager::user_login_state::UserAuthProcess;
use crate::{errors::FlowyError, notification::*};
use flowy_user_pub::session::Session;

use super::manager_user_workspace::save_user_workspace;

pub struct UserManager {
  pub(crate) cloud_services: Arc<dyn UserCloudServiceProvider>,
  pub(crate) store_preferences: Arc<KVStorePreferences>,
  pub(crate) user_awareness: Arc<ArcSwapOption<RwLock<UserAwareness>>>,
  pub(crate) user_status_callback: RwLock<Arc<dyn UserStatusCallback>>,
  pub(crate) collab_builder: Weak<AppFlowyCollabBuilder>,
  pub(crate) collab_interact: RwLock<Arc<dyn CollabInteract>>,
  pub(crate) user_workspace_service: Arc<dyn UserWorkspaceService>,
  auth_process: Mutex<Option<UserAuthProcess>>,
  pub(crate) authenticate_user: Arc<AuthenticateUser>,
  refresh_user_profile_since: AtomicI64,
  pub(crate) is_loading_awareness: Arc<DashMap<String, bool>>,
}

impl UserManager {
  pub fn new(
    cloud_services: Arc<dyn UserCloudServiceProvider>,
    store_preferences: Arc<KVStorePreferences>,
    collab_builder: Weak<AppFlowyCollabBuilder>,
    authenticate_user: Arc<AuthenticateUser>,
    user_workspace_service: Arc<dyn UserWorkspaceService>,
  ) -> Arc<Self> {
    let user_status_callback: RwLock<Arc<dyn UserStatusCallback>> =
      RwLock::new(Arc::new(DefaultUserStatusCallback));

    let refresh_user_profile_since = AtomicI64::new(0);
    let user_manager = Arc::new(Self {
      cloud_services,
      store_preferences,
      user_awareness: Default::default(),
      user_status_callback,
      collab_builder,
      collab_interact: RwLock::new(Arc::new(DefaultCollabInteract)),
      auth_process: Default::default(),
      authenticate_user,
      refresh_user_profile_since,
      user_workspace_service,
      is_loading_awareness: Arc::new(Default::default()),
    });

    let weak_user_manager = Arc::downgrade(&user_manager);
    if let Ok(user_service) = user_manager.cloud_services.get_user_service() {
      if let Some(mut rx) = user_service.subscribe_user_update() {
        af_spawn(async move {
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
  pub async fn init_with_callback<C: UserStatusCallback + 'static, I: CollabInteract>(
    &self,
    user_status_callback: C,
    collab_interact: I,
  ) -> Result<(), FlowyError> {
    let user_status_callback = Arc::new(user_status_callback);
    *self.user_status_callback.write().await = user_status_callback.clone();
    *self.collab_interact.write().await = Arc::new(collab_interact);

    if let Ok(session) = self.get_session() {
      let user = self.get_user_profile_from_disk(session.user_id).await?;

      // Get the current authenticator from the environment variable
      let current_authenticator = current_authenticator();

      // If the current authenticator is different from the authenticator in the session and it's
      // not a local authenticator, we need to sign out the user.
      if user.authenticator != Authenticator::Local && user.authenticator != current_authenticator {
        event!(
          tracing::Level::INFO,
          "Authenticator changed from {:?} to {:?}",
          user.authenticator,
          current_authenticator
        );
        self.sign_out().await?;
        return Ok(());
      }

      event!(
        tracing::Level::INFO,
        "init user session: {}:{}, authenticator: {:?}",
        user.uid,
        user.email,
        user.authenticator,
      );

      self.prepare_user(&session).await;
      self.prepare_backup(&session).await;

      // Set the token if the current cloud service using token to authenticate
      // Currently, only the AppFlowy cloud using token to init the client api.
      // TODO(nathan): using trait to separate the init process for different cloud service
      if user.authenticator.is_appflowy_cloud() {
        if let Err(err) = self.cloud_services.set_token(&user.token) {
          error!("Set token failed: {}", err);
        }

        if let Err(err) = self.cloud_services.set_ai_model(&user.ai_model) {
          error!("Set ai model failed: {}", err);
        }

        // Subscribe the token state
        let weak_cloud_services = Arc::downgrade(&self.cloud_services);
        let weak_authenticate_user = Arc::downgrade(&self.authenticate_user);
        let weak_pool = Arc::downgrade(&self.db_pool(user.uid)?);
        let cloned_session = session.clone();
        if let Some(mut token_state_rx) = self.cloud_services.subscribe_token_state() {
          event!(tracing::Level::DEBUG, "Listen token state change");
          let user_uid = user.uid;
          let local_token = user.token.clone();
          af_spawn(async move {
            while let Some(token_state) = token_state_rx.next().await {
              debug!("Token state changed: {:?}", token_state);
              match token_state {
                UserTokenState::Refresh { token: new_token } => {
                  // Only save the token if the token is different from the current token
                  if new_token != local_token {
                    if let Some(conn) = weak_pool.upgrade().and_then(|pool| pool.get().ok()) {
                      // Save the new token
                      if let Err(err) = save_user_token(user_uid, conn, new_token) {
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

      // Do the user data migration if needed
      event!(tracing::Level::INFO, "Prepare user data migration");
      match (
        self
          .authenticate_user
          .database
          .get_collab_db(session.user_id),
        self.authenticate_user.database.get_pool(session.user_id),
      ) {
        (Ok(collab_db), Ok(sqlite_pool)) => {
          run_collab_data_migration(
            &session,
            &user,
            collab_db,
            sqlite_pool,
            Some(self.authenticate_user.user_config.app_version.clone()),
          );
        },
        _ => error!("Failed to get collab db or sqlite pool"),
      }
      self.authenticate_user.vacuum_database_if_need();
      let cloud_config = get_cloud_config(session.user_id, &self.store_preferences);
      // Init the user awareness. here we ignore the error
      let _ = self
        .initial_user_awareness(&session, &user.authenticator)
        .await;

      user_status_callback
        .did_init(
          user.uid,
          &user.authenticator,
          &cloud_config,
          &session.user_workspace,
          &self.authenticate_user.user_config.device_id,
          &user.authenticator,
        )
        .await?;
    }
    Ok(())
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
    self
      .authenticate_user
      .database
      .get_collab_db(uid)
      .map(|collab_db| Arc::downgrade(&collab_db))
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
    authenticator: Authenticator,
  ) -> Result<UserProfile, FlowyError> {
    self.cloud_services.set_user_authenticator(&authenticator);

    let response: AuthResponse = self
      .cloud_services
      .get_user_service()?
      .sign_in(BoxAny::new(params))
      .await?;
    let session = Session::from(&response);
    self.prepare_user(&session).await;

    let latest_workspace = response.latest_workspace.clone();
    let user_profile = UserProfile::from((&response, &authenticator));
    self
      .save_auth_data(&response, &authenticator, &session)
      .await?;

    let _ = self
      .initial_user_awareness(&session, &user_profile.authenticator)
      .await;
    self
      .user_status_callback
      .read()
      .await
      .did_sign_in(
        user_profile.uid,
        &latest_workspace,
        &self.authenticate_user.user_config.device_id,
        &authenticator,
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
    authenticator: Authenticator,
    params: BoxAny,
  ) -> Result<UserProfile, FlowyError> {
    // sign out the current user if there is one
    let migration_user = self.get_migration_user(&authenticator).await;

    self.cloud_services.set_user_authenticator(&authenticator);
    let auth_service = self.cloud_services.get_user_service()?;
    let response: AuthResponse = auth_service.sign_up(params).await?;
    let new_user_profile = UserProfile::from((&response, &authenticator));
    if new_user_profile.encryption_type.require_encrypt_secret() {
      self.auth_process.lock().await.replace(UserAuthProcess {
        user_profile: new_user_profile.clone(),
        migration_user,
        response,
        authenticator,
      });
    } else {
      self
        .continue_sign_up(&new_user_profile, migration_user, response, &authenticator)
        .await?;
    }
    Ok(new_user_profile)
  }

  #[tracing::instrument(level = "info", skip(self))]
  pub async fn resume_sign_up(&self) -> Result<(), FlowyError> {
    let UserAuthProcess {
      user_profile,
      migration_user,
      response,
      authenticator,
    } = self
      .auth_process
      .lock()
      .await
      .clone()
      .ok_or(FlowyError::new(
        ErrorCode::Internal,
        "No resumable sign up data",
      ))?;
    self
      .continue_sign_up(&user_profile, migration_user, response, &authenticator)
      .await?;
    Ok(())
  }

  #[tracing::instrument(level = "info", skip_all, err)]
  async fn continue_sign_up(
    &self,
    new_user_profile: &UserProfile,
    migration_user: Option<AnonUser>,
    response: AuthResponse,
    authenticator: &Authenticator,
  ) -> FlowyResult<()> {
    let new_session = Session::from(&response);
    self.prepare_user(&new_session).await;
    self
      .save_auth_data(&response, authenticator, &new_session)
      .await?;
    let _ = self
      .initial_user_awareness(&new_session, &new_user_profile.authenticator)
      .await;
    self
      .user_status_callback
      .read()
      .await
      .did_sign_up(
        response.is_new_user,
        new_user_profile,
        &new_session.user_workspace,
        &self.authenticate_user.user_config.device_id,
        authenticator,
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

      if let Some(old_user) = migration_user {
        event!(
          tracing::Level::INFO,
          "Migrate anon user data from {:?} to {:?}",
          old_user.session.user_id,
          new_user_profile.uid
        );
        self
          .migrate_anon_user_data_to_cloud(&old_user, &new_session, authenticator)
          .await?;
        self.remove_anon_user();
        let _ = self
          .authenticate_user
          .database
          .close(old_user.session.user_id);
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
        &self.cloud_services,
        &session,
        &self.authenticate_user,
        self.db_connection(session.user_id)?,
      )
      .await?;
    }
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
      self.db_connection(session.user_id)?,
      changeset,
    )?;

    let profile = self.get_user_profile_from_disk(session.user_id).await?;
    self
      .update_user(session.user_id, profile.token, params)
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
      .backup_or_restore(session.user_id, &session.user_workspace.id);
  }

  /// Fetches the user profile for the given user ID.
  pub async fn get_user_profile_from_disk(&self, uid: i64) -> Result<UserProfile, FlowyError> {
    select_user_profile(uid, self.db_connection(uid)?)
  }

  #[tracing::instrument(level = "info", skip_all, err)]
  pub async fn refresh_user_profile(&self, old_user_profile: &UserProfile) -> FlowyResult<()> {
    // If the user is a local user, no need to refresh the user profile
    if old_user_profile.authenticator.is_local() {
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
      .cloud_services
      .get_user_service()?
      .get_user_profile(UserCredentials::from_uid(uid))
      .await;

    match result {
      Ok(new_user_profile) => {
        // If the user profile is updated, save the new user profile
        if new_user_profile.updated_at > old_user_profile.updated_at {
          validate_encryption_sign(old_user_profile, &new_user_profile.encryption_type.sign());
          // Save the new user profile
          let changeset = UserTableChangeset::from_user_profile(new_user_profile);
          let _ = upsert_user_profile_change(
            uid,
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

  pub fn workspace_id(&self) -> Result<String, FlowyError> {
    let session = self.get_session()?;
    Ok(session.user_workspace.id.clone())
  }

  pub fn token(&self) -> Result<Option<String>, FlowyError> {
    Ok(None)
  }

  async fn update_user(
    &self,
    uid: i64,
    token: String,
    params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    let server = self.cloud_services.get_user_service()?;
    af_spawn(async move {
      let credentials = UserCredentials::new(Some(token), Some(uid), None);
      server.update_user(credentials, params).await
    })
    .await
    .map_err(internal_error)??;
    Ok(())
  }

  async fn save_user(&self, uid: i64, user: UserTable) -> Result<(), FlowyError> {
    let mut conn = self.db_connection(uid)?;
    conn.immediate_transaction(|conn| {
      // delete old user if exists
      diesel::delete(user_table::dsl::user_table.filter(user_table::dsl::id.eq(&user.id)))
        .execute(conn)?;

      let _ = diesel::insert_into(user_table::table)
        .values(user)
        .execute(conn)?;
      Ok::<(), FlowyError>(())
    })?;

    Ok(())
  }

  pub async fn receive_realtime_event(&self, json: Value) {
    if let Ok(user_service) = self.cloud_services.get_user_service() {
      user_service.receive_realtime_event(json)
    }
  }

  pub(crate) async fn generate_sign_in_url_with_email(
    &self,
    authenticator: &Authenticator,
    email: &str,
  ) -> Result<String, FlowyError> {
    self.cloud_services.set_user_authenticator(authenticator);

    let auth_service = self.cloud_services.get_user_service()?;
    let url = auth_service.generate_sign_in_url_with_email(email).await?;
    Ok(url)
  }

  pub(crate) async fn sign_in_with_magic_link(
    &self,
    email: &str,
    redirect_to: &str,
  ) -> Result<(), FlowyError> {
    self
      .cloud_services
      .set_user_authenticator(&Authenticator::AppFlowyCloud);
    let auth_service = self.cloud_services.get_user_service()?;
    auth_service
      .sign_in_with_magic_link(email, redirect_to)
      .await?;
    Ok(())
  }

  pub(crate) async fn generate_oauth_url(
    &self,
    oauth_provider: &str,
  ) -> Result<String, FlowyError> {
    self
      .cloud_services
      .set_user_authenticator(&Authenticator::AppFlowyCloud);
    let auth_service = self.cloud_services.get_user_service()?;
    let url = auth_service
      .generate_oauth_url_with_provider(oauth_provider)
      .await?;
    Ok(url)
  }

  #[instrument(level = "info", skip_all, err)]
  async fn save_auth_data(
    &self,
    response: &impl UserAuthResponse,
    authenticator: &Authenticator,
    session: &Session,
  ) -> Result<(), FlowyError> {
    let user_profile = UserProfile::from((response, authenticator));
    let uid = user_profile.uid;
    if authenticator.is_local() {
      event!(tracing::Level::DEBUG, "Save new anon user: {:?}", uid);
      self.set_anon_user(session);
    }

    save_all_user_workspaces(uid, self.db_connection(uid)?, response.user_workspaces())?;
    info!(
      "Save new user profile to disk, authenticator: {:?}",
      authenticator
    );

    self
      .authenticate_user
      .set_session(Some(session.clone().into()))?;
    self
      .save_user(uid, (user_profile, authenticator.clone()).into())
      .await?;
    Ok(())
  }

  async fn handler_user_update(&self, user_update: UserUpdate) -> FlowyResult<()> {
    let session = self.get_session()?;
    if session.user_id == user_update.uid {
      debug!("Receive user update: {:?}", user_update);
      let user_profile = self.get_user_profile_from_disk(user_update.uid).await?;
      if !validate_encryption_sign(&user_profile, &user_update.encryption_sign) {
        return Ok(());
      }

      // Save the user profile change
      upsert_user_profile_change(
        user_update.uid,
        self.db_connection(user_update.uid)?,
        UserTableChangeset::from(user_update),
      )?;
    }

    Ok(())
  }

  async fn migrate_anon_user_data_to_cloud(
    &self,
    old_user: &AnonUser,
    _new_user_session: &Session,
    authenticator: &Authenticator,
  ) -> Result<(), FlowyError> {
    let old_collab_db = self
      .authenticate_user
      .database
      .get_collab_db(old_user.session.user_id)?;

    if authenticator == &Authenticator::AppFlowyCloud {
      self
        .migration_anon_user_on_appflowy_cloud_sign_up(old_user, &old_collab_db)
        .await?;
    }

    // Save the old user workspace setting.
    save_user_workspace(
      old_user.session.user_id,
      self
        .authenticate_user
        .database
        .get_connection(old_user.session.user_id)?,
      &old_user.session.user_workspace.clone(),
    )?;
    Ok(())
  }
}

fn current_authenticator() -> Authenticator {
  match AuthenticatorType::from_env() {
    AuthenticatorType::Local => Authenticator::Local,
    AuthenticatorType::AppFlowyCloud => Authenticator::AppFlowyCloud,
  }
}

pub fn upsert_user_profile_change(
  uid: i64,
  mut conn: DBConnection,
  changeset: UserTableChangeset,
) -> FlowyResult<()> {
  event!(
    tracing::Level::DEBUG,
    "Update user profile with changeset: {:?}",
    changeset
  );
  diesel_update_table!(user_table, changeset, &mut *conn);
  let user: UserProfile = user_table::dsl::user_table
    .filter(user_table::id.eq(&uid.to_string()))
    .first::<UserTable>(&mut *conn)?
    .into();
  send_notification(&uid.to_string(), UserNotification::DidUpdateUserProfile)
    .payload(UserProfilePB::from(user))
    .send();
  Ok(())
}

#[instrument(level = "info", skip_all, err)]
fn save_user_token(uid: i64, conn: DBConnection, token: String) -> FlowyResult<()> {
  let params = UpdateUserProfileParams::new(uid).with_token(token);
  let changeset = UserTableChangeset::new(params);
  upsert_user_profile_change(uid, conn, changeset)
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

pub(crate) fn run_collab_data_migration(
  session: &Session,
  user: &UserProfile,
  collab_db: Arc<CollabKVDB>,
  sqlite_pool: Arc<ConnectionPool>,
  version: Option<Version>,
) {
  trace!("Run collab data migration: {:?}", version);
  let migrations = collab_migration_list();
  match UserLocalDataMigration::new(session.clone(), collab_db, sqlite_pool).run(
    migrations,
    &user.authenticator,
    version,
  ) {
    Ok(applied_migrations) => {
      if !applied_migrations.is_empty() {
        info!("Did apply migrations: {:?}", applied_migrations);
      }
    },
    Err(e) => error!("User data migration failed: {:?}", e),
  }
}

pub async fn sign_out(
  cloud_services: &Arc<dyn UserCloudServiceProvider>,
  session: &Session,
  authenticate_user: &AuthenticateUser,
  conn: DBConnection,
) -> Result<(), FlowyError> {
  let _ = remove_user_token(session.user_id, conn);
  authenticate_user.database.close(session.user_id)?;
  authenticate_user.set_session(None)?;

  let server = cloud_services.get_user_service()?;
  if let Err(err) = server.sign_out(None).await {
    event!(tracing::Level::ERROR, "{:?}", err);
  }

  Ok(())
}
