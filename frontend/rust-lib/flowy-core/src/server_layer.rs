use crate::AppFlowyCoreConfig;
use af_plugin::manager::PluginManager;
use arc_swap::{ArcSwap, ArcSwapOption};
use dashmap::mapref::one::Ref;
use dashmap::DashMap;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_error::{FlowyError, FlowyResult};
use flowy_server::af_cloud::define::AIUserServiceImpl;
use flowy_server::af_cloud::{define::LoggedUser, AppFlowyCloudServer};
use flowy_server::local_server::LocalServer;
use flowy_server::{AppFlowyEncryption, AppFlowyServer, EncryptionImpl};
use flowy_server_pub::AuthenticatorType;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user_pub::entities::*;
use std::ops::Deref;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Weak};
use tracing::info;

pub struct ServerProvider {
  config: AppFlowyCoreConfig,
  providers: DashMap<AuthType, Arc<dyn AppFlowyServer>>,
  auth_type: ArcSwap<AuthType>,
  logged_user: Arc<dyn LoggedUser>,
  pub local_ai: Arc<LocalAIController>,
  pub uid: Arc<ArcSwapOption<i64>>,
  pub user_enable_sync: Arc<AtomicBool>,
  pub encryption: Arc<dyn AppFlowyEncryption>,
}

// Our little guard wrapper:
pub struct ServerHandle<'a>(Ref<'a, AuthType, Arc<dyn AppFlowyServer>>);

#[allow(clippy::needless_lifetimes)]
impl<'a> Deref for ServerHandle<'a> {
  type Target = dyn AppFlowyServer;
  fn deref(&self) -> &Self::Target {
    // `self.0.value()` is an `&Arc<dyn AppFlowyServer>`
    // so `&**` gives us a `&dyn AppFlowyServer`
    &**self.0.value()
  }
}

/// Determine current server type from ENV
pub fn current_server_type() -> AuthType {
  match AuthenticatorType::from_env() {
    AuthenticatorType::Local => AuthType::Local,
    AuthenticatorType::AppFlowyCloud => AuthType::AppFlowyCloud,
  }
}

impl ServerProvider {
  pub fn new(
    config: AppFlowyCoreConfig,
    store_preferences: Weak<KVStorePreferences>,
    user_service: impl LoggedUser + 'static,
  ) -> Self {
    let initial_auth = current_server_type();
    let logged_user = Arc::new(user_service) as Arc<dyn LoggedUser>;
    let auth_type = ArcSwap::from(Arc::new(initial_auth));
    let encryption = Arc::new(EncryptionImpl::new(None)) as Arc<dyn AppFlowyEncryption>;
    let ai_user = Arc::new(AIUserServiceImpl(Arc::downgrade(&logged_user)));
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
      logged_user,
      uid: Default::default(),
      local_ai,
    }
  }

  pub fn on_launch_if_authenticated(&self, _workspace_type: &WorkspaceType) {
    self.local_ai.reload_ollama_client();
  }

  pub fn on_sign_in(&self, _workspace_type: &WorkspaceType) {
    self.local_ai.reload_ollama_client();
  }

  pub fn on_sign_up(&self, workspace_type: &WorkspaceType) {
    if workspace_type.is_local() {
      self.local_ai.reload_ollama_client();
    }
  }
  pub fn init_after_open_workspace(&self, _workspace_type: &WorkspaceType) {
    self.local_ai.reload_ollama_client();
  }

  pub fn set_auth_type(&self, new_auth_type: AuthType) {
    let old_type = self.get_auth_type();
    if old_type != new_auth_type {
      info!(
        "ServerProvider: auth type from {:?} to {:?}",
        old_type, new_auth_type
      );

      self.auth_type.store(Arc::new(new_auth_type));
      if let Some((auth_type, _)) = self.providers.remove(&old_type) {
        info!("ServerProvider: remove old auth type: {:?}", auth_type);
      }
    }
  }

  pub fn get_auth_type(&self) -> AuthType {
    *self.auth_type.load_full().as_ref()
  }

  /// Lazily create or fetch an AppFlowyServer instance
  pub fn get_server(&self) -> FlowyResult<ServerHandle> {
    let auth_type = self.get_auth_type();
    if let Some(r) = self.providers.get(&auth_type) {
      return Ok(ServerHandle(r));
    }

    let server: Arc<dyn AppFlowyServer> = match auth_type {
      AuthType::Local => Arc::new(LocalServer::new(
        self.logged_user.clone(),
        self.local_ai.clone(),
      )),
      AuthType::AppFlowyCloud => {
        let cfg = self
          .config
          .cloud_config
          .clone()
          .ok_or_else(|| FlowyError::internal().with_context("Missing cloud config"))?;
        let ai_user_service = Arc::new(AIUserServiceImpl(Arc::downgrade(&self.logged_user)));
        Arc::new(AppFlowyCloudServer::new(
          cfg,
          self.user_enable_sync.load(Ordering::Acquire),
          self.config.device_id.clone(),
          self.config.app_version.clone(),
          Arc::downgrade(&self.logged_user),
          ai_user_service,
        ))
      },
    };

    self.providers.insert(auth_type, server);
    let guard = self.providers.get(&auth_type).unwrap();
    Ok(ServerHandle(guard))
  }
}
