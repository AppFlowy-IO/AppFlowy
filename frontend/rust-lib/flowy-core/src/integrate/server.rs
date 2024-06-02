use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use std::sync::{Arc, Weak};

use parking_lot::RwLock;
use serde_repr::*;

use flowy_error::{FlowyError, FlowyResult};
use flowy_server::af_cloud::define::ServerUser;
use flowy_server::af_cloud::AppFlowyCloudServer;
use flowy_server::local_server::{LocalServer, LocalServerDB};
use flowy_server::supabase::SupabaseServer;
use flowy_server::{AppFlowyEncryption, AppFlowyServer, EncryptionImpl};
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_server_pub::supabase_config::SupabaseConfiguration;
use flowy_server_pub::AuthenticatorType;
use flowy_sqlite::kv::StorePreferences;
use flowy_user_pub::entities::*;

use crate::AppFlowyCoreConfig;

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

impl Server {
  pub fn is_local(&self) -> bool {
    matches!(self, Server::Local)
  }
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
  providers: RwLock<HashMap<Server, Arc<dyn AppFlowyServer>>>,
  pub(crate) encryption: RwLock<Arc<dyn AppFlowyEncryption>>,
  #[allow(dead_code)]
  pub(crate) store_preferences: Weak<StorePreferences>,
  pub(crate) user_enable_sync: RwLock<bool>,

  /// The authenticator type of the user.
  authenticator: RwLock<Authenticator>,
  user: Arc<dyn ServerUser>,
  pub(crate) uid: Arc<RwLock<Option<i64>>>,
}

impl ServerProvider {
  pub fn new(
    config: AppFlowyCoreConfig,
    server: Server,
    store_preferences: Weak<StorePreferences>,
    server_user: impl ServerUser + 'static,
  ) -> Self {
    let user = Arc::new(server_user);
    let encryption = EncryptionImpl::new(None);
    Self {
      config,
      providers: RwLock::new(HashMap::new()),
      user_enable_sync: RwLock::new(true),
      authenticator: RwLock::new(Authenticator::from(server)),
      encryption: RwLock::new(Arc::new(encryption)),
      store_preferences,
      uid: Default::default(),
      user,
    }
  }

  pub fn get_server_type(&self) -> Server {
    match &*self.authenticator.read() {
      Authenticator::Local => Server::Local,
      Authenticator::AppFlowyCloud => Server::AppFlowyCloud,
      Authenticator::Supabase => Server::Supabase,
    }
  }

  pub fn set_authenticator(&self, authenticator: Authenticator) {
    let old_server_type = self.get_server_type();
    *self.authenticator.write() = authenticator;
    let new_server_type = self.get_server_type();

    if old_server_type != new_server_type {
      self.providers.write().remove(&old_server_type);
    }
  }

  pub fn get_authenticator(&self) -> Authenticator {
    self.authenticator.read().clone()
  }

  /// Returns a [AppFlowyServer] trait implementation base on the provider_type.
  pub fn get_server(&self) -> FlowyResult<Arc<dyn AppFlowyServer>> {
    let server_type = self.get_server_type();

    if let Some(provider) = self.providers.read().get(&server_type) {
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
          *self.user_enable_sync.read(),
          self.config.device_id.clone(),
          self.config.app_version.clone(),
          self.user.clone(),
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
          *self.user_enable_sync.read(),
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

pub fn current_server_type() -> Server {
  match AuthenticatorType::from_env() {
    AuthenticatorType::Local => Server::Local,
    AuthenticatorType::Supabase => Server::Supabase,
    AuthenticatorType::AppFlowyCloud => Server::AppFlowyCloud,
  }
}

struct LocalServerDBImpl {
  #[allow(dead_code)]
  storage_path: String,
}

impl LocalServerDB for LocalServerDBImpl {
  fn get_user_profile(&self, _uid: i64) -> Result<UserProfile, FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("LocalServer doesn't support get_user_profile"),
    )
  }

  fn get_user_workspace(&self, _uid: i64) -> Result<Option<UserWorkspace>, FlowyError> {
    Err(
      FlowyError::local_version_not_support()
        .with_context("LocalServer doesn't support get_user_workspace"),
    )
  }
}
