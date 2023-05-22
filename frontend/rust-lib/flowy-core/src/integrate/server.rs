use lib_infra::future::FutureResult;
use std::collections::HashMap;
use std::sync::Arc;

use parking_lot::RwLock;

use flowy_error::{ErrorCode, FlowyError};
use flowy_folder2::deps::{FolderCloudService, Workspace};
use flowy_server::local_server::LocalServer;
use flowy_server::self_host::configuration::self_host_server_configuration;
use flowy_server::self_host::SelfHostServer;
use flowy_server::supabase::{SupabaseConfiguration, SupabaseServer};
use flowy_server::AppFlowyServer;
use flowy_sqlite::kv::KV;
use flowy_user::event_map::{UserAuthService, UserCloudServiceProvider};
use flowy_user::services::AuthType;

use serde::{Deserialize, Serialize};
use serde_repr::*;

const SERVER_PROVIDER_TYPE_KEY: &str = "server_provider_type";

#[derive(Debug, Clone, Hash, Eq, PartialEq, Serialize_repr, Deserialize_repr)]
pub enum ServerProviderType {
  Local,
  SelfHosted,
  Supabase,
}

/// The [AppFlowyServerProvider] provides list of [AppFlowyServer] base on the [AuthType]. Using
/// the auth type, the [AppFlowyServerProvider] will create a new [AppFlowyServer] if it doesn't
/// exist.
/// Each server implements the [AppFlowyServer] trait, which provides the [UserAuthService], etc.
pub struct AppFlowyServerProvider {
  current_provider: RwLock<ServerProviderType>,
  providers: RwLock<HashMap<ServerProviderType, Arc<dyn AppFlowyServer>>>,
}

impl AppFlowyServerProvider {
  pub fn new() -> Self {
    Self {
      current_provider: RwLock::new(current_server_provider()),
      providers: RwLock::new(HashMap::new()),
    }
  }

  fn get_provider(&self, provider_type: &ServerProviderType) -> Arc<dyn AppFlowyServer> {
    if let Some(provider) = self.providers.read().get(provider_type) {
      return provider.clone();
    }

    let server = server_from_auth_type(provider_type)?;
    self
      .providers
      .write()
      .insert(provider_type.clone(), server.clone());
    server
  }
}

impl UserCloudServiceProvider for AppFlowyServerProvider {
  fn set_auth_type(&self, auth_type: AuthType) {
    let provider_type: ServerProviderType = auth_type.into();
    match KV::set_object(SERVER_PROVIDER_TYPE_KEY, provider_type) {
      Ok(_) => tracing::trace!("Update server provider type to: {:?}", provider_type),
      Err(e) => {
        tracing::error!("🔴Failed to update server provider type: {:?}", e);
      },
    }
  }

  /// Returns the [UserAuthService] base on the current [ServerProviderType].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_auth_service(&self, auth_type: &AuthType) -> Result<Arc<dyn UserAuthService>, FlowyError> {
    let provider_type: ServerProviderType = auth_type.into();
    Ok(self.get_provider(&provider_type).user_service())
  }
}

impl FolderCloudService for AppFlowyServerProvider {
  fn create_workspace(&self, _name: &str) -> FutureResult<Workspace, FlowyError> {
    let server = self.get_provider(&self.current_provider.read());
    server.
  }
}

fn server_from_auth_type(
  provider: &ServerProviderType,
) -> Result<Arc<dyn AppFlowyServer>, FlowyError> {
  match provider {
    ServerProviderType::Local => {
      let server = Arc::new(LocalServer::new());
      Ok(server)
    },
    ServerProviderType::SelfHosted => {
      let config = self_host_server_configuration().map_err(|e| {
        FlowyError::new(
          ErrorCode::InvalidAuthConfig,
          format!("Missing self host config: {:?}. Error: {:?}", provider, e),
        )
      })?;
      let server = Arc::new(SelfHostServer::new(config));
      Ok(server)
    },
    ServerProviderType::Supabase => {
      // init the SupabaseServerConfiguration from the environment variables.
      let config = SupabaseConfiguration::from_env()?;
      let server = Arc::new(SupabaseServer::new(config));
      Ok(server)
    },
  }
}

impl From<AuthType> for ServerProviderType {
  fn from(auth_provider: AuthType) -> Self {
    match auth_provider {
      AuthType::Local => ServerProviderType::Local,
      AuthType::SelfHosted => ServerProviderType::SelfHosted,
      AuthType::Supabase => ServerProviderType::Supabase,
    }
  }
}

impl From<&AuthType> for ServerProviderType {
  fn from(auth_provider: &AuthType) -> Self {
    Self::from(auth_provider.clone())
  }
}

fn current_server_provider() -> ServerProviderType {
  match KV::get_object::<ServerProviderType>(SERVER_PROVIDER_TYPE_KEY) {
    None => ServerProviderType::Local,
    Some(provider_type) => provider_type,
  }
}
