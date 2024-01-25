use collab::preclude::CollabPlugin;
use collab_integrate::collab_builder::{
  CollabCloudPluginProvider, CollabPluginProviderContext, CollabPluginProviderType,
};
use flowy_server::af_cloud::AppFlowyCloudServer;
use flowy_server::AppFlowyServer;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_user_pub::entities::Authenticator;
use lib_infra::future::Fut;
use std::rc::Rc;
use std::sync::Arc;

#[derive(Clone)]
pub struct ServerProviderWASM {
  authenticator: Authenticator,
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
    Self {
      authenticator: Authenticator::AppFlowyCloud,
      server,
    }
  }
}

impl CollabCloudPluginProvider for ServerProviderWASM {
  fn provider_type(&self) -> CollabPluginProviderType {
    CollabPluginProviderType::AppFlowyCloud
  }

  fn get_plugins(&self, context: CollabPluginProviderContext) -> Fut<Vec<Arc<dyn CollabPlugin>>> {
    todo!()
  }

  fn is_sync_enabled(&self) -> bool {
    true
  }
}
