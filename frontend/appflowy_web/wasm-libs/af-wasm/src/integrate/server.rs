use collab::preclude::CollabPlugin;
use collab_integrate::collab_builder::{
  CollabCloudPluginProvider, CollabPluginProviderContext, CollabPluginProviderType,
};
use flowy_error::FlowyError;
use flowy_server::af_cloud::AppFlowyCloudServer;
use flowy_server::AppFlowyServer;
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_storage::{ObjectIdentity, ObjectStorageService, ObjectValue};
use flowy_user_pub::cloud::{UserCloudService, UserCloudServiceProvider};
use flowy_user_pub::entities::{Authenticator, UserTokenState};
use lib_infra::future::{to_fut, Fut, FutureResult};
use parking_lot::RwLock;
use std::rc::Rc;
use std::sync::Arc;
use tokio_stream::wrappers::WatchStream;
use tracing::{info, warn};

pub struct ServerProviderWASM {
  device_id: String,
  config: AFCloudConfiguration,
  server: RwLock<Option<Rc<dyn AppFlowyServer>>>,
}

impl ServerProviderWASM {
  pub fn new(device_id: &str, config: AFCloudConfiguration) -> Self {
    info!("Server config: {}", config);
    Self {
      device_id: device_id.to_string(),
      server: RwLock::new(Default::default()),
      config,
    }
  }

  pub fn get_server(&self) -> Rc<dyn AppFlowyServer> {
    let server = self.server.read().as_ref().cloned();
    match server {
      Some(server) => server,
      None => {
        let server = Rc::new(AppFlowyCloudServer::new(
          self.config.clone(),
          true,
          self.device_id.clone(),
          "0.0.1",
        ));
        *self.server.write() = Some(server.clone());
        server
      },
    }
  }
}

impl CollabCloudPluginProvider for ServerProviderWASM {
  fn provider_type(&self) -> CollabPluginProviderType {
    CollabPluginProviderType::AppFlowyCloud
  }

  fn get_plugins(&self, _context: CollabPluginProviderContext) -> Vec<Box<dyn CollabPlugin>> {
    vec![]
  }

  fn is_sync_enabled(&self) -> bool {
    true
  }
}

impl UserCloudServiceProvider for ServerProviderWASM {
  fn set_token(&self, token: &str) -> Result<(), FlowyError> {
    self.get_server().set_token(token)?;
    Ok(())
  }

  fn set_ai_model(&self, ai_model: &str) -> Result<(), FlowyError> {
    Ok(())
  }

  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>> {
    self.get_server().subscribe_token_state()
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
    Ok(self.get_server().user_service())
  }

  fn service_url(&self) -> String {
    self.config.base_url.clone()
  }
}

impl ObjectStorageService for ServerProviderWASM {
  fn get_object_url(&self, object_id: ObjectIdentity) -> FutureResult<String, FlowyError> {
    todo!()
  }

  fn put_object(&self, url: String, object_value: ObjectValue) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn delete_object(&self, url: String) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_object(&self, url: String) -> FutureResult<ObjectValue, FlowyError> {
    todo!()
  }
}
