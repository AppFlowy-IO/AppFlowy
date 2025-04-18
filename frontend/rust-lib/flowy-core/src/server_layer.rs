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
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Weak};

pub struct ServerProvider {
  config: AppFlowyCoreConfig,
  providers: DashMap<AuthType, Arc<dyn AppFlowyServer>>,
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
    initial_auth: AuthType,
    store_preferences: Weak<KVStorePreferences>,
    user_service: impl LoginUserService + 'static,
  ) -> Self {
    let user = Arc::new(user_service);
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

  pub fn set_auth_type(&self, new_auth_type: AuthType) {
    let old_type = self.get_auth_type();
    if old_type != new_auth_type {
      self.auth_type.store(Arc::new(new_auth_type));
      self.providers.remove(&old_type);
    }
  }

  pub fn get_auth_type(&self) -> AuthType {
    *self.auth_type.load_full().as_ref()
  }

  /// Lazily create or fetch an AppFlowyServer instance
  pub fn get_server(&self) -> FlowyResult<Arc<dyn AppFlowyServer>> {
    let auth_type = self.get_auth_type();
    if let Some(entry) = self.providers.get(&auth_type) {
      return Ok(entry.clone());
    }

    let server: Arc<dyn AppFlowyServer> = match auth_type {
      AuthType::Local => Arc::new(LocalServer::new(self.user.clone(), self.local_ai.clone())),
      AuthType::AppFlowyCloud => {
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

    self.providers.insert(auth_type, server.clone());
    Ok(server)
  }
}

/// Determine current server type from ENV
pub fn current_server_type() -> AuthType {
  match AuthenticatorType::from_env() {
    AuthenticatorType::Local => AuthType::Local,
    AuthenticatorType::AppFlowyCloud => AuthType::AppFlowyCloud,
  }
}
