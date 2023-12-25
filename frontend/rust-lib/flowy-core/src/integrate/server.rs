use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use std::sync::{Arc, Weak};

use parking_lot::RwLock;
use serde_repr::*;

use flowy_error::{FlowyError, FlowyResult};
use flowy_server::af_cloud::AppFlowyCloudServer;
use flowy_server::local_server::{LocalServer, LocalServerDB};
use flowy_server::supabase::SupabaseServer;
use flowy_server::{AppFlowyEncryption, AppFlowyServer, EncryptionImpl};
use flowy_server_config::af_cloud_config::AFCloudConfiguration;
use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_sqlite::kv::StorePreferences;
use flowy_user::services::db::{get_user_profile, get_user_workspace, open_user_db};
use flowy_user_deps::entities::*;

use crate::AppFlowyCoreConfig;

pub(crate) const SERVER_PROVIDER_TYPE_KEY: &str = "server_provider_type";

#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum Server {
  /// Local server provider.
  /// Offline mode, no user authentication and the data is stored locally.
  Local = 0,
  /// AppFlowy Cloud server provider.
  /// The [AppFlowy-Server](https://github.com/AppFlowy-IO/AppFlowy-Cloud) is still a work in
  /// progress.
  AppFlowyCloud = 1,
  /// Supabase server provider.
  /// It uses supabase postgresql database to store data and user authentication.
  Supabase = 2,
}

impl Display for Server {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    match self {
      Server::Local => write!(f, "Local"),
      Server::AppFlowyCloud => write!(f, "AppFlowyCloud"),
      Server::Supabase => write!(f, "Supabase"),
    }
  }
}

/// The [ServerProvider] provides list of [AppFlowyServer] base on the [Authenticator]. Using
/// the auth type, the [ServerProvider] will create a new [AppFlowyServer] if it doesn't
/// exist.
/// Each server implements the [AppFlowyServer] trait, which provides the [UserCloudService], etc.
pub struct ServerProvider {
  config: AppFlowyCoreConfig,
  server: RwLock<Server>,
  providers: RwLock<HashMap<Server, Arc<dyn AppFlowyServer>>>,
  pub(crate) encryption: RwLock<Arc<dyn AppFlowyEncryption>>,
  pub(crate) store_preferences: Weak<StorePreferences>,
  pub(crate) enable_sync: RwLock<bool>,
  pub(crate) uid: Arc<RwLock<Option<i64>>>,
}

impl ServerProvider {
  pub fn new(
    config: AppFlowyCoreConfig,
    server: Server,
    store_preferences: Weak<StorePreferences>,
  ) -> Self {
    let encryption = EncryptionImpl::new(None);
    Self {
      config,
      server: RwLock::new(server),
      providers: RwLock::new(HashMap::new()),
      enable_sync: RwLock::new(true),
      encryption: RwLock::new(Arc::new(encryption)),
      store_preferences,
      uid: Default::default(),
    }
  }

  pub fn get_server_type(&self) -> Server {
    self.server.read().clone()
  }

  pub fn set_server_type(&self, server_type: Server) {
    let old_server_type = self.server.read().clone();
    if server_type != old_server_type {
      self.providers.write().remove(&old_server_type);
    }

    *self.server.write() = server_type;
  }

  /// Returns a [AppFlowyServer] trait implementation base on the provider_type.
  pub(crate) fn get_server(&self, server_type: &Server) -> FlowyResult<Arc<dyn AppFlowyServer>> {
    if let Some(provider) = self.providers.read().get(server_type) {
      return Ok(provider.clone());
    }

    let server = match server_type {
      Server::Local => {
        let local_db = Arc::new(LocalServerDBImpl {
          storage_path: self.config.storage_path.clone(),
        });
        let server = Arc::new(LocalServer::new(local_db));
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      Server::AppFlowyCloud => {
        let config = AFCloudConfiguration::from_env()?;
        let server = Arc::new(AppFlowyCloudServer::new(
          config,
          *self.enable_sync.read(),
          self.config.device_id.clone(),
        ));

        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(server)
      },
      Server::Supabase => {
        let config = SupabaseConfiguration::from_env()?;
        let uid = self.uid.clone();
        tracing::trace!("🔑Supabase config: {:?}", config);
        let encryption = Arc::downgrade(&*self.encryption.read());
        Ok::<Arc<dyn AppFlowyServer>, FlowyError>(Arc::new(SupabaseServer::new(
          uid,
          config,
          *self.enable_sync.read(),
          self.config.device_id.clone(),
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

impl From<Authenticator> for Server {
  fn from(auth_provider: Authenticator) -> Self {
    match auth_provider {
      Authenticator::Local => Server::Local,
      Authenticator::AppFlowyCloud => Server::AppFlowyCloud,
      Authenticator::Supabase => Server::Supabase,
    }
  }
}

impl From<Server> for Authenticator {
  fn from(ty: Server) -> Self {
    match ty {
      Server::Local => Authenticator::Local,
      Server::AppFlowyCloud => Authenticator::AppFlowyCloud,
      Server::Supabase => Authenticator::Supabase,
    }
  }
}
impl From<&Authenticator> for Server {
  fn from(auth_provider: &Authenticator) -> Self {
    Self::from(auth_provider.clone())
  }
}

pub fn current_server_type(store_preferences: &Arc<StorePreferences>) -> Server {
  store_preferences
    .get_object::<Server>(SERVER_PROVIDER_TYPE_KEY)
    .unwrap_or(Server::Local)
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
}
