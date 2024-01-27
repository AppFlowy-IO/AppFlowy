use collab::preclude::CollabPlugin;
use collab_integrate::collab_builder::{
  CollabCloudPluginProvider, CollabPluginProviderContext, CollabPluginProviderType,
};
use flowy_error::FlowyError;
use flowy_server::af_cloud::AppFlowyCloudServer;
use flowy_server::AppFlowyServer;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_user_pub::cloud::{
  UserCloudService, UserCloudServiceProvider, UserCloudServiceProviderBase,
};
use flowy_user_pub::entities::{Authenticator, UserTokenState};
use lib_infra::future::Fut;
use std::rc::Rc;
use std::sync::Arc;
use tokio_stream::wrappers::WatchStream;
use tracing::warn;

#[derive(Clone)]
pub struct ServerProviderWASM {
  server: Rc<dyn AppFlowyServer>,
}

impl ServerProviderWASM {
  pub fn new(device_id: &str) -> Self {
    let config = AFCloudConfiguration::from_env().unwrap();
    let server = Rc::new(AppFlowyCloudServer::new(
      config,
      true,
      device_id.to_string(),
    ));
    Self { server }
  }
}

impl CollabCloudPluginProvider for ServerProviderWASM {
  fn provider_type(&self) -> CollabPluginProviderType {
    CollabPluginProviderType::AppFlowyCloud
  }

  fn get_plugins(&self, _context: CollabPluginProviderContext) -> Fut<Vec<Arc<dyn CollabPlugin>>> {
    todo!()
  }

  fn is_sync_enabled(&self) -> bool {
    true
  }
}

impl UserCloudServiceProvider for ServerProviderWASM {}

impl UserCloudServiceProviderBase for ServerProviderWASM {
  fn set_token(&self, token: &str) -> Result<(), FlowyError> {
    self.server.set_token(token)?;
    Ok(())
  }

  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    self.server.subscribe_token_state()
  }

  fn set_enable_sync(&self, _uid: i64, _enable_sync: bool) {
    warn!("enable sync is not supported in wasm")
  }

  fn set_user_authenticator(&self, _authenticator: &Authenticator) {
    warn!("set user authenticator is not supported in wasm")
  }

  fn get_user_authenticator(&self) -> Authenticator {
    Authenticator::AppFlowyCloud
  }

  fn set_network_reachable(&self, _reachable: bool) {
    warn!("set network reachable is not supported in wasm")
  }

  fn set_encrypt_secret(&self, _secret: String) {
    warn!("set encrypt secret is not supported in wasm")
  }

  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError> {
    Ok(self.server.user_service())
  }

  fn service_url(&self) -> String {
    AFCloudConfiguration::from_env()
      .map(|config| config.base_url)
      .unwrap_or_default()
  }
}
