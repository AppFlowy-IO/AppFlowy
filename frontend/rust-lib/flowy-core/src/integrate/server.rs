use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use std::sync::{Arc, Weak};

use parking_lot::RwLock;
use serde_repr::*;

use collab_integrate::YrsDocAction;
use flowy_error::{FlowyError, FlowyResult};
use flowy_server::af_cloud::AFCloudServer;
use flowy_server::local_server::{LocalServer, LocalServerDB};
use flowy_server::supabase::SupabaseServer;
use flowy_server::{AppFlowyEncryption, AppFlowyServer, EncryptionImpl};
use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_sqlite::kv::StorePreferences;
use flowy_user::services::database::{
  get_user_profile, get_user_workspace, open_collab_db, open_user_db,
};
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;

use crate::AppFlowyCoreConfig;

pub(crate) const SERVER_PROVIDER_TYPE_KEY: &str = "server_provider_type";

#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ServerType {
  /// Local server provider.
  /// Offline mode, no user authentication and the data is stored locally.
  Local = 0,
  /// AppFlowy Cloud server provider.
  /// The [AppFlowy-Server](https://github.com/AppFlowy-IO/AppFlowy-Cloud) is still a work in
  /// progress.
  AFCloud = 1,
  /// Supabase server provider.
  /// It uses supabase postgresql database to store data and user authentication.
  Supabase = 2,
}

impl Display for ServerType {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      ServerType::Local => write!(f, "Local"),
      ServerType::AFCloud => write!(f, "AppFlowyCloud"),
      ServerType::Supabase => write!(f, "Supabase"),
    }
  }
}

/// The [ServerProvider] provides list of [AppFlowyServer] base on the [AuthType]. Using
/// the auth type, the [ServerProvider] will create a new [AppFlowyServer] if it doesn't
/// exist.
/// Each server implements the [AppFlowyServer] trait, which provides the [UserCloudService], etc.
pub struct ServerProvider {
  config: AppFlowyCoreConfig,
  server_type: RwLock<ServerType>,
  providers: RwLock<HashMap<ServerType, Arc<dyn AppFlowyServer>>>,
  pub(crate) encryption: RwLock<Arc<dyn AppFlowyEncryption>>,
  pub(crate) store_preferences: Weak<StorePreferences>,
  pub(crate) cache_user_service: RwLock<HashMap<ServerType, Arc<dyn UserCloudService>>>,

  pub(crate) device_id: Arc<RwLock<String>>,
  pub(crate) enable_sync: RwLock<bool>,
  pub(crate) uid: Arc<RwLock<Option<i64>>>,
}

impl ServerProvider {
  pub fn new(
    config: AppFlowyCoreConfig,
    provider_type: ServerType,
    store_preferences: Weak<StorePreferences>,
  ) -> Self {
    let encryption = EncryptionImpl::new(None);
    Self {
      config,
      server_type: RwLock::new(provider_type),
      device_id: Arc::new(RwLock::new(uuid::Uuid::new_v4().to_string())),
      providers: RwLock::new(HashMap::new()),
      enable_sync: RwLock::new(true),
      encryption: RwLock::new(Arc::new(encryption)),
      store_preferences,
      cache_user_service: Default::default(),
      uid: Default::default(),
    }
  }

  pub fn get_server_type(&self) -> ServerType {
    self.server_type.read().clone()
  }

  pub fn set_server_type(&self, server_type: ServerType) {
    let old_server_type = self.server_type.read().clone();
    if server_type != old_server_type {
      self.providers.write().remove(&old_server_type);
    }

    *self.server_type.write() = server_type;
  }

  /// Returns a [AppFlowyServer] trait implementation base on the provider_type.
  pub(crate) fn get_server(
    &self,
    server_type: &ServerType,
  ) -> FlowyResult<Arc<dyn AppFlowyServer>> {
    if let Some(provider) = self.providers.read().get(server_type) {
      return Ok(provider.clone());
    }

    let server = match server_type {
      ServerType::Local => {
        let local_db = Arc::new(LocalServerDBImpl {
          storage_path: self.config.storage_path.clone(),
        });
        let server = Arc::new(LocalServer::new(local_db));
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      ServerType::AFCloud => {
        let config = AFCloudConfiguration::from_env()?;
        tracing::trace!("🔑AppFlowy cloud config: {:?}", config);
        let server = Arc::new(AFCloudServer::new(
          config,
          *self.enable_sync.read(),
          self.device_id.clone(),
        ));

        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      ServerType::Supabase => {
        let config = match SupabaseConfiguration::from_env() {
          Ok(config) => config,
          Err(e) => {
            *self.enable_sync.write() = false;
            return Err(e);
          },
        };
        let uid = self.uid.clone();
        tracing::trace!("🔑Supabase config: {:?}", config);
        let encryption = Arc::downgrade(&*self.encryption.read());
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(Arc::new(SupabaseServer::new(
          uid,
          config,
          *self.enable_sync.read(),
          self.device_id.clone(),
          encryption,
        )))
      },
    }?;

    self
      .providers
      .write()
      .insert(server_type.clone(), server.clone());
    Ok(server)
  }
}

impl From<AuthType> for ServerType {
  fn from(auth_provider: AuthType) -> Self {
    match auth_provider {
      AuthType::Local => ServerType::Local,
      AuthType::AFCloud => ServerType::AFCloud,
      AuthType::Supabase => ServerType::Supabase,
    }
  }
}

impl From<&AuthType> for ServerType {
  fn from(auth_provider: &AuthType) -> Self {
    Self::from(auth_provider.clone())
  }
}

pub fn current_server_provider(store_preferences: &Arc<StorePreferences>) -> ServerType {
  match store_preferences.get_object::<ServerType>(SERVER_PROVIDER_TYPE_KEY) {
    None => ServerType::Local,
    Some(provider_type) => provider_type,
  }
}

struct LocalServerDBImpl {
  storage_path: String,
}

impl LocalServerDB for LocalServerDBImpl {
  fn get_user_profile(&self, uid: i64) -> Result<UserProfile, FlowyError> {
    let sqlite_db = open_user_db(&self.storage_path, uid)?;
    let user_profile = get_user_profile(&sqlite_db, uid)?;
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
    let updates = read_txn.get_all_updates(uid, object_id).map_err(|e| {
      FlowyError::internal().with_context(format!("Failed to open collab db: {:?}", e))
    })?;

    Ok(updates)
  }
}
