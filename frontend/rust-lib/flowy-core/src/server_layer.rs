use crate::AppFlowyCoreConfig;
use af_plugin::manager::PluginManager;
use arc_swap::{ArcSwap, ArcSwapOption};
use dashmap::DashMap;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_error::{FlowyError, FlowyResult};
use flowy_server::af_cloud::{
  define::{AIUserServiceImpl, LoginUserService},
  AppFlowyCloudServer,
};
use flowy_server::local_server::LocalServer;
use flowy_server::{AppFlowyEncryption, AppFlowyServer, EncryptionImpl};
use flowy_server_pub::AuthenticatorType;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::entities::*;
use serde_repr::{Deserialize_repr, Serialize_repr};
use std::fmt::{Display, Formatter, Result as FmtResult};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Weak};

/// ServerType: local or cloud
#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum ServerType {
  Local = 0,
  AppFlowyCloud = 1,
}

impl ServerType {
  pub fn is_local(&self) -> bool {
    matches!(self, Self::Local)
  }
}

impl Display for ServerType {
  fn fmt(&self, f: &mut Formatter<'_>) -> FmtResult {
    write!(f, "{:?}", self)
  }
}

/// Conversion between AuthType and ServerType
impl From<&AuthType> for ServerType {
  fn from(a: &AuthType) -> Self {
    match a {
      AuthType::Local => ServerType::Local,
      AuthType::AppFlowyCloud => ServerType::AppFlowyCloud,
    }
  }
}
impl From<ServerType> for AuthType {
  fn from(s: ServerType) -> Self {
    match s {
      ServerType::Local => AuthType::Local,
      ServerType::AppFlowyCloud => AuthType::AppFlowyCloud,
    }
  }
}

pub struct ServerProvider {
  config: AppFlowyCoreConfig,
  providers: DashMap<ServerType, Arc<dyn AppFlowyServer>>,
  auth_type: ArcSwap<AuthType>,
  user: Arc<dyn LoginUserService>,
  pub local_ai: Arc<LocalAIController>,
  pub uid: Arc<ArcSwapOption<i64>>,
  pub user_enable_sync: Arc<AtomicBool>,
  pub encryption: Arc<dyn AppFlowyEncryption>,
}

impl ServerProvider {
  pub fn new(
    config: AppFlowyCoreConfig,
    initial: ServerType,
    store_preferences: Weak<KVStorePreferences>,
    user_service: impl LoginUserService + 'static,
  ) -> Self {
    let user = Arc::new(user_service);
    let initial_auth = AuthType::from(initial);
    let auth_type = ArcSwap::from(Arc::new(initial_auth));
    let encryption = Arc::new(EncryptionImpl::new(None)) as Arc<dyn AppFlowyEncryption>;
    let ai_user = Arc::new(AIUserServiceImpl(user.clone()));
    let plugins = Arc::new(PluginManager::new());
    let local_ai = Arc::new(LocalAIController::new(
      plugins,
      store_preferences,
      ai_user.clone(),
    ));

    ServerProvider {
      config,
      providers: DashMap::new(),
      encryption,
      user_enable_sync: Arc::new(AtomicBool::new(true)),
      auth_type,
      user,
      uid: Default::default(),
      local_ai,
    }
  }

  /// Reads current type
  pub fn get_server_type(&self) -> ServerType {
    let auth_type = self.auth_type.load_full();
    ServerType::from(auth_type.as_ref())
  }

  pub fn set_auth_type(&self, a: AuthType) {
    let old_type = self.get_server_type();
    self.auth_type.store(Arc::new(a));
    let new_type = self.get_server_type();
    if old_type != new_type {
      self.providers.remove(&old_type);
    }
  }

  pub fn get_auth_type(&self) -> AuthType {
    *self.auth_type.load_full().as_ref()
  }

  /// Lazily create or fetch an AppFlowyServer instance
  pub fn get_server(&self) -> FlowyResult<Arc<dyn AppFlowyServer>> {
    let key = self.get_server_type();
    if let Some(entry) = self.providers.get(&key) {
      return Ok(entry.clone());
    }

    let server: Arc<dyn AppFlowyServer> = match key {
      ServerType::Local => Arc::new(LocalServer::new(self.user.clone(), self.local_ai.clone())),
      ServerType::AppFlowyCloud => {
        let cfg = self
          .config
          .cloud_config
          .clone()
          .ok_or_else(|| FlowyError::internal().with_context("Missing cloud config"))?;
        Arc::new(AppFlowyCloudServer::new(
          cfg,
          self.user_enable_sync.load(Ordering::Acquire),
          self.config.device_id.clone(),
          self.config.app_version.clone(),
          self.user.clone(),
        ))
      },
    };

    self.providers.insert(key.clone(), server.clone());
    Ok(server)
  }
}

/// Determine current server type from ENV
pub fn current_server_type() -> ServerType {
  match AuthenticatorType::from_env() {
    AuthenticatorType::Local => ServerType::Local,
    AuthenticatorType::AppFlowyCloud => ServerType::AppFlowyCloud,
  }
}
