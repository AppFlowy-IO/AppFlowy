use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use std::sync::{Arc, Weak};

use appflowy_integrate::collab_builder::{CollabStorageProvider, CollabStorageType};
use appflowy_integrate::{CollabObject, CollabType, RemoteCollabStorage, YrsDocAction};
use parking_lot::{Mutex, RwLock};
use serde_json::Value;
use serde_repr::*;

use flowy_database_deps::cloud::*;
use flowy_document2::deps::DocumentData;
use flowy_document_deps::cloud::{DocumentCloudService, DocumentSnapshot};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_folder_deps::cloud::*;
use flowy_server::local_server::{LocalServer, LocalServerDB};
use flowy_server::self_host::configuration::self_host_server_configuration;
use flowy_server::self_host::SelfHostServer;
use flowy_server::supabase::SupabaseServer;
use flowy_server::AppFlowyServer;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_sqlite::kv::StorePreferences;
use flowy_user::event_map::UserCloudServiceProvider;
use flowy_user::services::database::{
  get_user_profile, get_user_workspace, open_collab_db, open_user_db,
};
use flowy_user_deps::cloud::UserService;
use flowy_user_deps::entities::*;
use lib_infra::future::FutureResult;

use crate::AppFlowyCoreConfig;

const SERVER_PROVIDER_TYPE_KEY: &str = "server_provider_type";

#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ServerProviderType {
  /// Local server provider.
  /// Offline mode, no user authentication and the data is stored locally.
  Local = 0,
  /// Self-hosted server provider.
  /// The [AppFlowy-Server](https://github.com/AppFlowy-IO/AppFlowy-Cloud) is still a work in
  /// progress.
  AppFlowyCloud = 1,
  /// Supabase server provider.
  /// It uses supabase's postgresql database to store data and user authentication.
  Supabase = 2,
}

impl Display for ServerProviderType {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      ServerProviderType::Local => write!(f, "Local"),
      ServerProviderType::AppFlowyCloud => write!(f, "AppFlowyCloud"),
      ServerProviderType::Supabase => write!(f, "Supabase"),
    }
  }
}

/// The [AppFlowyServerProvider] provides list of [AppFlowyServer] base on the [AuthType]. Using
/// the auth type, the [AppFlowyServerProvider] will create a new [AppFlowyServer] if it doesn't
/// exist.
/// Each server implements the [AppFlowyServer] trait, which provides the [UserService], etc.
pub struct AppFlowyServerProvider {
  config: AppFlowyCoreConfig,
  provider_type: RwLock<ServerProviderType>,
  device_id: Mutex<String>,
  providers: RwLock<HashMap<ServerProviderType, Arc<dyn AppFlowyServer>>>,
  supabase_config: RwLock<Option<SupabaseConfiguration>>,
  store_preferences: Weak<StorePreferences>,
}

impl AppFlowyServerProvider {
  pub fn new(
    config: AppFlowyCoreConfig,
    provider_type: ServerProviderType,
    supabase_config: Option<SupabaseConfiguration>,
    store_preferences: Weak<StorePreferences>,
  ) -> Self {
    Self {
      config,
      provider_type: RwLock::new(provider_type),
      device_id: Default::default(),
      providers: RwLock::new(HashMap::new()),
      supabase_config: RwLock::new(supabase_config),
      store_preferences,
    }
  }

  pub fn set_sync_device(&self, device_id: &str) {
    *self.device_id.lock() = device_id.to_string();
  }

  pub fn provider_type(&self) -> ServerProviderType {
    self.provider_type.read().clone()
  }

  /// Returns a [AppFlowyServer] trait implementation base on the provider_type.
  fn get_provider(
    &self,
    provider_type: &ServerProviderType,
  ) -> FlowyResult<Arc<dyn AppFlowyServer>> {
    if let Some(provider) = self.providers.read().get(provider_type) {
      return Ok(provider.clone());
    }

    let server = match provider_type {
      ServerProviderType::Local => {
        let local_db = Arc::new(LocalServerDBImpl {
          storage_path: self.config.storage_path.clone(),
        });
        let server = Arc::new(LocalServer::new(local_db));

        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      ServerProviderType::AppFlowyCloud => {
        let config = self_host_server_configuration().map_err(|e| {
          FlowyError::new(
            ErrorCode::InvalidAuthConfig,
            format!(
              "Missing self host config: {:?}. Error: {:?}",
              provider_type, e
            ),
          )
        })?;
        let server = Arc::new(SelfHostServer::new(config));
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      ServerProviderType::Supabase => {
        let config = self.supabase_config.read().clone().ok_or(FlowyError::new(
          ErrorCode::InvalidAuthConfig,
          "Missing supabase config".to_string(),
        ))?;
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(Arc::new(SupabaseServer::new(config)))
      },
    }?;
    server.set_sync_device_id(&self.device_id.lock());

    self
      .providers
      .write()
      .insert(provider_type.clone(), server.clone());
    Ok(server)
  }

  pub fn handle_realtime_event(&self, json: Value) {
    let provider_type = self.provider_type.read().clone();
    if let Some(server) = self.providers.read().get(&provider_type) {
      server.handle_realtime_event(json);
    }
  }
}

impl UserCloudServiceProvider for AppFlowyServerProvider {
  fn update_supabase_config(&self, supabase_config: &SupabaseConfiguration) {
    self
      .supabase_config
      .write()
      .replace(supabase_config.clone());

    supabase_config.write_env();
    if let Ok(provider) = self.get_provider(&self.provider_type.read()) {
      provider.enable_sync(supabase_config.enable_sync);
    }
  }

  /// When user login, the provider type is set by the [AuthType] and save to disk for next use.
  ///
  /// Each [AuthType] has a corresponding [ServerProviderType]. The [ServerProviderType] is used
  /// to create a new [AppFlowyServer] if it doesn't exist. Once the [ServerProviderType] is set,
  /// it will be used when user open the app again.
  ///
  fn set_auth_type(&self, auth_type: AuthType) {
    let provider_type: ServerProviderType = auth_type.into();
    *self.provider_type.write() = provider_type.clone();

    match self.store_preferences.upgrade() {
      None => tracing::error!("🔴Failed to update server provider type: store preferences is drop"),
      Some(store_preferences) => {
        match store_preferences.set_object(SERVER_PROVIDER_TYPE_KEY, provider_type.clone()) {
          Ok(_) => tracing::trace!("Update server provider type to: {:?}", provider_type),
          Err(e) => {
            tracing::error!("🔴Failed to update server provider type: {:?}", e);
          },
        }
      },
    }
  }

  /// Returns the [UserService] base on the current [ServerProviderType].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_user_service(&self) -> Result<Arc<dyn UserService>, FlowyError> {
    Ok(
      self
        .get_provider(&self.provider_type.read())?
        .user_service(),
    )
  }

  fn service_name(&self) -> String {
    self.provider_type.read().to_string()
  }
}

impl FolderCloudService for AppFlowyServerProvider {
  fn create_workspace(&self, uid: i64, name: &str) -> FutureResult<Workspace, Error> {
    let server = self.get_provider(&self.provider_type.read());
    let name = name.to_string();
    FutureResult::new(async move { server?.folder_service().create_workspace(uid, &name).await })
  }

  fn get_folder_data(&self, workspace_id: &str) -> FutureResult<Option<FolderData>, Error> {
    let server = self.get_provider(&self.provider_type.read());
    let workspace_id = workspace_id.to_string();
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_data(&workspace_id)
        .await
    })
  }

  fn get_folder_latest_snapshot(
    &self,
    workspace_id: &str,
  ) -> FutureResult<Option<FolderSnapshot>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_provider(&self.provider_type.read());
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_latest_snapshot(&workspace_id)
        .await
    })
  }

  fn get_folder_updates(&self, workspace_id: &str, uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    let workspace_id = workspace_id.to_string();
    let server = self.get_provider(&self.provider_type.read());
    FutureResult::new(async move {
      server?
        .folder_service()
        .get_folder_updates(&workspace_id, uid)
        .await
    })
  }

  fn service_name(&self) -> String {
    self
      .get_provider(&self.provider_type.read())
      .map(|provider| provider.folder_service().service_name())
      .unwrap_or_default()
  }
}

impl DatabaseCloudService for AppFlowyServerProvider {
  fn get_collab_update(
    &self,
    object_id: &str,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdate, Error> {
    let server = self.get_provider(&self.provider_type.read());
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_collab_update(&database_id, object_ty)
        .await
    })
  }

  fn batch_get_collab_updates(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> FutureResult<CollabObjectUpdateByOid, Error> {
    let server = self.get_provider(&self.provider_type.read());
    FutureResult::new(async move {
      server?
        .database_service()
        .batch_get_collab_updates(object_ids, object_ty)
        .await
    })
  }

  fn get_collab_latest_snapshot(
    &self,
    object_id: &str,
  ) -> FutureResult<Option<DatabaseSnapshot>, Error> {
    let server = self.get_provider(&self.provider_type.read());
    let database_id = object_id.to_string();
    FutureResult::new(async move {
      server?
        .database_service()
        .get_collab_latest_snapshot(&database_id)
        .await
    })
  }
}

impl DocumentCloudService for AppFlowyServerProvider {
  fn get_document_updates(&self, document_id: &str) -> FutureResult<Vec<Vec<u8>>, Error> {
    let server = self.get_provider(&self.provider_type.read());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_updates(&document_id)
        .await
    })
  }

  fn get_document_latest_snapshot(
    &self,
    document_id: &str,
  ) -> FutureResult<Option<DocumentSnapshot>, Error> {
    let server = self.get_provider(&self.provider_type.read());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_latest_snapshot(&document_id)
        .await
    })
  }

  fn get_document_data(&self, document_id: &str) -> FutureResult<Option<DocumentData>, Error> {
    let server = self.get_provider(&self.provider_type.read());
    let document_id = document_id.to_string();
    FutureResult::new(async move {
      server?
        .document_service()
        .get_document_data(&document_id)
        .await
    })
  }
}

impl CollabStorageProvider for AppFlowyServerProvider {
  fn storage_type(&self) -> CollabStorageType {
    self.provider_type().into()
  }

  fn get_storage(
    &self,
    collab_object: &CollabObject,
    storage_type: &CollabStorageType,
  ) -> Option<Arc<dyn RemoteCollabStorage>> {
    match storage_type {
      CollabStorageType::Local => None,
      CollabStorageType::AWS => None,
      CollabStorageType::Supabase => self
        .get_provider(&ServerProviderType::Supabase)
        .ok()
        .and_then(|provider| provider.collab_storage(collab_object)),
    }
  }

  fn is_sync_enabled(&self) -> bool {
    self
      .supabase_config
      .read()
      .as_ref()
      .map(|config| config.enable_sync)
      .unwrap_or(false)
  }
}

impl From<AuthType> for ServerProviderType {
  fn from(auth_provider: AuthType) -> Self {
    match auth_provider {
      AuthType::Local => ServerProviderType::Local,
      AuthType::SelfHosted => ServerProviderType::AppFlowyCloud,
      AuthType::Supabase => ServerProviderType::Supabase,
    }
  }
}

impl From<&AuthType> for ServerProviderType {
  fn from(auth_provider: &AuthType) -> Self {
    Self::from(auth_provider.clone())
  }
}

pub fn current_server_provider(store_preferences: &Arc<StorePreferences>) -> ServerProviderType {
  match store_preferences.get_object::<ServerProviderType>(SERVER_PROVIDER_TYPE_KEY) {
    None => ServerProviderType::Local,
    Some(provider_type) => provider_type,
  }
}

struct LocalServerDBImpl {
  storage_path: String,
}

impl LocalServerDB for LocalServerDBImpl {
  fn get_user_profile(&self, uid: i64) -> Result<Option<UserProfile>, FlowyError> {
    let sqlite_db = open_user_db(&self.storage_path, uid)?;
    let user_profile = get_user_profile(&sqlite_db, uid).ok();
    Ok(user_profile)
  }

  fn get_user_workspace(&self, uid: i64) -> Result<Option<UserWorkspace>, FlowyError> {
    let sqlite_db = open_user_db(&self.storage_path, uid)?;
    let user_workspace = get_user_workspace(&sqlite_db, uid)?;
    Ok(user_workspace)
  }

  fn get_collab_updates(&self, uid: i64, object_id: &str) -> Result<Vec<Vec<u8>>, FlowyError> {
    let collab_db = open_collab_db(&self.storage_path, uid)?;
    let read_txn = collab_db.read_txn();
    let updates = read_txn
      .get_all_updates(uid, object_id)
      .map_err(|e| FlowyError::internal().context(format!("Failed to open collab db: {:?}", e)))?;

    Ok(updates)
  }
}
