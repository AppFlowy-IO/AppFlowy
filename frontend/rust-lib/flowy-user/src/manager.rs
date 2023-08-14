use std::string::ToString;
use std::sync::{Arc, Weak};

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::RocksCollabDB;
use collab_folder::core::FolderData;
use collab_user::core::MutexUserAwareness;
use serde_json::Value;
use tokio::sync::{Mutex, RwLock};
use uuid::Uuid;

use flowy_error::{internal_error, ErrorCode};
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_sqlite::kv::StorePreferences;
use flowy_sqlite::schema::user_table;
use flowy_sqlite::ConnectionPool;
use flowy_sqlite::{query_dsl::*, DBConnection, ExpressionMethods};
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;

use crate::entities::{UserProfilePB, UserSettingPB};
use crate::event_map::{
  DefaultUserStatusCallback, SignUpContext, UserCloudServiceProvider, UserStatusCallback,
};
use crate::migrations::historical_document::HistoricalEmptyDocumentMigration;
use crate::migrations::local_user_to_cloud::migration_user_to_cloud;
use crate::migrations::migration::UserLocalDataMigration;
use crate::migrations::UserMigrationContext;
use crate::services::database::UserDB;
use crate::services::entities::Session;
use crate::services::user_awareness::UserAwarenessDataSource;
use crate::services::user_sql::{UserTable, UserTableChangeset};
use crate::services::user_workspace::save_user_workspaces;
use crate::{errors::FlowyError, notification::*};

const SUPABASE_CONFIG_CACHE_KEY: &str = "af_supabase_config";

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

pub struct UserManager {
  database: UserDB,
  session_config: UserSessionConfig,
  pub(crate) cloud_services: Arc<dyn UserCloudServiceProvider>,
  pub(crate) store_preferences: Arc<StorePreferences>,
  pub(crate) user_awareness: Arc<Mutex<Option<MutexUserAwareness>>>,
  pub(crate) user_status_callback: RwLock<Arc<dyn UserStatusCallback>>,
  pub(crate) collab_builder: Weak<AppFlowyCollabBuilder>,
}

impl UserManager {
  pub fn new(
    session_config: UserSessionConfig,
    cloud_services: Arc<dyn UserCloudServiceProvider>,
    store_preferences: Arc<StorePreferences>,
    collab_builder: Weak<AppFlowyCollabBuilder>,
  ) -> Self {
    let database = UserDB::new(&session_config.root_dir);
    let user_status_callback: RwLock<Arc<dyn UserStatusCallback>> =
      RwLock::new(Arc::new(DefaultUserStatusCallback));
    Self {
      database,
      session_config,
      cloud_services,
      store_preferences,
      user_awareness: Arc::new(Default::default()),
      user_status_callback,
      collab_builder,
    }
  }

  pub fn get_store_preferences(&self) -> Weak<StorePreferences> {
    Arc::downgrade(&self.store_preferences)
  }

  /// Initializes the user session, including data migrations and user awareness configuration.
  ///
  /// This asynchronous function starts by retrieving the current session. If the session is successfully obtained,
  /// it will attempt a local data migration for the user. After ensuring the user's data is migrated and up-to-date,
  /// the function will set up the collaboration configuration and initialize the user's awareness. Upon successful
  /// completion, a user status callback is invoked to signify that the initialization process is complete.
  pub async fn init<C: UserStatusCallback + 'static>(&self, user_status_callback: C) {
    if let Ok(session) = self.get_session() {
      // Do the user data migration if needed
      match (
        self.database.get_collab_db(session.user_id),
        self.database.get_pool(session.user_id),
      ) {
        (Ok(collab_db), Ok(sqlite_pool)) => {
          match UserLocalDataMigration::new(session.clone(), collab_db, sqlite_pool)
            .run(vec![Box::new(HistoricalEmptyDocumentMigration)])
          {
            Ok(applied_migrations) => {
              if !applied_migrations.is_empty() {
                tracing::info!("Did apply migrations: {:?}", applied_migrations);
              }
            },
            Err(e) => tracing::error!("User data migration failed: {:?}", e),
          }
        },
        _ => tracing::error!("Failed to get collab db or sqlite pool"),
      }
      self.set_collab_config(&session);
      // Init the user awareness
      self
        .initialize_user_awareness(&session, UserAwarenessDataSource::Local)
        .await;
      if let Err(e) = user_status_callback
        .did_init(session.user_id, &session.user_workspace, &session.device_id)
        .await
      {
        tracing::error!("Failed to call did_init callback: {:?}", e);
      }
    }
    *self.user_status_callback.write().await = Arc::new(user_status_callback);
  }

  pub fn db_connection(&self, uid: i64) -> Result<DBConnection, FlowyError> {
    self.database.get_connection(uid)
  }

  pub fn db_pool(&self, uid: i64) -> Result<Arc<ConnectionPool>, FlowyError> {
    self.database.get_pool(uid)
  }

  pub fn get_collab_db(&self, uid: i64) -> Result<Weak<RocksCollabDB>, FlowyError> {
    self
      .database
      .get_collab_db(uid)
      .map(|collab_db| Arc::downgrade(&collab_db))
  }

  /// Performs a user sign-in, initializing user awareness and sending relevant notifications.
  ///
  /// This asynchronous function interacts with an external user service to authenticate and sign in a user
  /// based on provided parameters. Once signed in, it updates the collaboration configuration, logs the user,
  /// saves their workspaces, and initializes their user awareness.
  ///
  /// A sign-in notification is also sent after a successful sign-in.
  ///
  #[tracing::instrument(level = "debug", skip(self, params))]
  pub async fn sign_in(
    &self,
    params: BoxAny,
    auth_type: AuthType,
  ) -> Result<UserProfile, FlowyError> {
    let response: SignInResponse = self
      .cloud_services
      .get_user_service()?
      .sign_in(params)
      .await?;
    let session: Session = response.clone().into();
    let uid = session.user_id;
    let device_id = session.device_id.clone();
    self.set_collab_config(&session);
    self.set_current_session(Some(session.clone()))?;
    self.log_historical_user(
      uid,
      &response.device_id,
      response.name.clone(),
      &auth_type,
      self.user_dir(uid),
    );
    let user_workspace = response.latest_workspace.clone();
    save_user_workspaces(uid, self.db_pool(uid)?, &response.user_workspaces)?;
    let user_profile: UserProfile = self
      .save_user(uid, (response, auth_type).into())
      .await?
      .into();
    let _ = self
      .initialize_user_awareness(&session, UserAwarenessDataSource::Remote)
      .await;

    if let Err(e) = self
      .user_status_callback
      .read()
      .await
      .did_sign_in(user_profile.id, &user_workspace, &device_id)
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

  /// Manages the user sign-up process, potentially migrating data if necessary.
  ///
  /// This asynchronous function interacts with an external authentication service to register and sign up a user
  /// based on the provided parameters. Following a successful sign-up, it handles configuration updates, logging,
  /// and saving workspace information. If a user is signing up with a new profile and previously had guest data,
  /// this function may migrate that data over to the new account.
  ///
  #[tracing::instrument(level = "debug", skip(self, params))]
  pub async fn sign_up(
    &self,
    auth_type: AuthType,
    params: BoxAny,
  ) -> Result<UserProfile, FlowyError> {
    let old_user = {
      if let Ok(old_session) = self.get_session() {
        self
          .get_user_profile(old_session.user_id, false)
          .await
          .ok()
          .map(|user_profile| UserMigrationContext {
            user_profile,
            session: old_session,
          })
      } else {
        None
      }
    };

    let auth_service = self.cloud_services.get_user_service()?;
    let response: SignUpResponse = auth_service.sign_up(params).await?;
    let mut sign_up_context = SignUpContext {
      is_new: response.is_new,
      local_folder: None,
    };
    let new_session = Session::from(&response);
    self.set_current_session(Some(new_session.clone()))?;
    self.set_collab_config(&new_session);
    let uid = response.user_id;
    self.log_historical_user(
      uid,
      &response.device_id,
      response.name.clone(),
      &auth_type,
      self.user_dir(uid),
    );
    save_user_workspaces(uid, self.db_pool(uid)?, &response.user_workspaces)?;
    let new_user_profile: UserProfile = self
      .save_user(uid, (response, auth_type.clone()).into())
      .await?
      .into();
    let user_awareness_source = if sign_up_context.is_new {
      UserAwarenessDataSource::Local
    } else {
      UserAwarenessDataSource::Remote
    };
    // Only migrate the data if the user is login in as a guest and sign up as a new user if the current
    // auth type is not [AuthType::Local].
    if sign_up_context.is_new {
      if let Some(old_user) = old_user {
        if old_user.user_profile.auth_type == AuthType::Local && !auth_type.is_local() {
          let new_user = UserMigrationContext {
            user_profile: new_user_profile.clone(),
            session: new_session.clone(),
          };
          tracing::info!(
            "Migrate old user data from {:?} to {:?}",
            old_user.user_profile.id,
            new_user.user_profile.id
          );
          match self.migrate_local_user_to_cloud(&old_user, &new_user).await {
            Ok(folder_data) => sign_up_context.local_folder = folder_data,
            Err(e) => tracing::error!("{:?}", e),
          }
          // close the old user db
          let _ = self.database.close(old_user.session.user_id);
        }
      }
    }

    self
      .initialize_user_awareness(&new_session, user_awareness_source)
      .await;

    let _ = self
      .user_status_callback
      .read()
      .await
      .did_sign_up(
        sign_up_context,
        &new_user_profile,
        &new_session.user_workspace,
        &new_session.device_id,
      )
      .await;
    Ok(new_user_profile)
  }

  #[tracing::instrument(level = "info", skip(self))]
  pub async fn sign_out(&self) -> Result<(), FlowyError> {
    let session = self.get_session()?;
    self.database.close(session.user_id)?;
    self.set_current_session(None)?;

    let server = self.cloud_services.get_user_service()?;
    tokio::spawn(async move {
      match server.sign_out(None).await {
        Ok(_) => {},
        Err(e) => tracing::error!("Sign out failed: {:?}", e),
      }
    });
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
    let auth_service = self.cloud_services.get_user_service()?;
    auth_service.check_user(credential).await?;
    Ok(())
  }

  pub async fn check_user_with_uuid(&self, uuid: &Uuid) -> Result<(), FlowyError> {
    let credential = UserCredentials::from_uuid(uuid.to_string());
    let auth_service = self.cloud_services.get_user_service()?;
    auth_service.check_user(credential).await?;
    Ok(())
  }

  /// Fetches the user profile for the given user ID.
  ///
  /// This function retrieves the user profile from the local database. If the `refresh` flag is set to `true`,
  /// it also attempts to update the user profile from a cloud service, and then sends a notification about the
  /// profile update.
  pub async fn get_user_profile(&self, uid: i64, refresh: bool) -> Result<UserProfile, FlowyError> {
    let user_id = uid.to_string();
    let user = user_table::dsl::user_table
      .filter(user_table::id.eq(&user_id))
      .first::<UserTable>(&*(self.db_connection(uid)?))?;

    if refresh {
      let weak_auth_service = Arc::downgrade(&self.cloud_services.get_user_service()?);
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
              let filter =
                user_table::dsl::user_table.filter(user_table::dsl::id.eq(changeset.id.clone()));
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

  pub fn user_dir(&self, uid: i64) -> String {
    format!("{}/{}", self.session_config.root_dir, uid)
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

  pub fn token(&self) -> Result<Option<String>, FlowyError> {
    Ok(None)
  }

  pub fn save_supabase_config(&self, config: SupabaseConfiguration) {
    self.cloud_services.set_supabase_config(&config);
    let _ = self
      .store_preferences
      .set_object(SUPABASE_CONFIG_CACHE_KEY, config);
  }

  async fn update_user(
    &self,
    _auth_type: &AuthType,
    uid: i64,
    token: Option<String>,
    params: UpdateUserProfileParams,
  ) -> Result<(), FlowyError> {
    let server = self.cloud_services.get_user_service()?;
    let token = token.to_owned();
    tokio::spawn(async move {
      let credentials = UserCredentials::new(token, Some(uid), None);
      server.update_user(credentials, params).await
    })
    .await
    .map_err(internal_error)??;
    Ok(())
  }

  async fn save_user(&self, uid: i64, user: UserTable) -> Result<UserTable, FlowyError> {
    let conn = self.db_connection(uid)?;
    conn.immediate_transaction(|| {
      // delete old user if exists
      diesel::delete(user_table::dsl::user_table.filter(user_table::dsl::id.eq(&user.id)))
        .execute(&*conn)?;

      let _ = diesel::insert_into(user_table::table)
        .values(user.clone())
        .execute(&*conn)?;
      Ok::<(), FlowyError>(())
    })?;

    Ok(user)
  }

  pub(crate) fn set_current_session(&self, session: Option<Session>) -> Result<(), FlowyError> {
    tracing::debug!("Set current user: {:?}", session);
    match &session {
      None => self
        .store_preferences
        .remove(&self.session_config.session_cache_key),
      Some(session) => {
        self
          .store_preferences
          .set_object(&self.session_config.session_cache_key, session.clone())
          .map_err(internal_error)?;
      },
    }
    Ok(())
  }

  pub async fn receive_realtime_event(&self, json: Value) {
    self
      .user_status_callback
      .read()
      .await
      .receive_realtime_event(json);
  }

  /// Returns the current user session.
  pub fn get_session(&self) -> Result<Session, FlowyError> {
    match self
      .store_preferences
      .get_object::<Session>(&self.session_config.session_cache_key)
    {
      None => Err(FlowyError::new(
        ErrorCode::RecordNotFound,
        "User is not logged in",
      )),
      Some(session) => Ok(session),
    }
  }

  fn set_collab_config(&self, session: &Session) {
    let collab_builder = self.collab_builder.upgrade().unwrap();
    collab_builder.set_sync_device(session.device_id.clone());
    collab_builder.initialize(session.user_workspace.id.clone());
    self.cloud_services.set_device_id(&session.device_id);
  }

  async fn migrate_local_user_to_cloud(
    &self,
    old_user: &UserMigrationContext,
    new_user: &UserMigrationContext,
  ) -> Result<Option<FolderData>, FlowyError> {
    let old_collab_db = self.database.get_collab_db(old_user.session.user_id)?;
    let new_collab_db = self.database.get_collab_db(new_user.session.user_id)?;
    let folder_data = migration_user_to_cloud(old_user, &old_collab_db, new_user, &new_collab_db)?;
    Ok(folder_data)
  }
}

pub fn get_supabase_config(
  store_preference: &Arc<StorePreferences>,
) -> Option<SupabaseConfiguration> {
  store_preference
    .get_str(SUPABASE_CONFIG_CACHE_KEY)
    .and_then(|s| serde_json::from_str(&s).ok())
    .unwrap_or_else(|| SupabaseConfiguration::from_env().ok())
}
