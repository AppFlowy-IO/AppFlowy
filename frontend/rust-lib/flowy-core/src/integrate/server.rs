use std::collections::HashMap;
use std::sync::Arc;

use parking_lot::RwLock;

use flowy_config::entities::{SUPABASE_JWT, SUPABASE_KEY, SUPABASE_URL};
use flowy_error::{ErrorCode, FlowyError};
use flowy_server::local_server::LocalServer;
use flowy_server::self_host::configuration::self_host_server_configuration;
use flowy_server::self_host::SelfHostServer;
use flowy_server::supabase::{SupabaseServer, SupabaseServerConfiguration};
use flowy_server::AppFlowyServer;
use flowy_user::event_map::{UserAuthService, UserCloudServiceProvider};
use flowy_user::services::AuthType;

/// The [AppFlowyServerProvider] provides list of [AppFlowyServer] base on the [AuthType]. Using
/// the auth type, the [AppFlowyServerProvider] will create a new [AppFlowyServer] if it doesn't
/// exist.
/// Each server implements the [AppFlowyServer] trait, which provides the [UserAuthService], etc.
pub struct AppFlowyServerProvider {
  providers: RwLock<HashMap<AuthType, Arc<dyn AppFlowyServer>>>,
}

impl AppFlowyServerProvider {
  pub fn new() -> Self {
    Self {
      providers: Default::default(),
    }
  }
}

impl UserCloudServiceProvider for AppFlowyServerProvider {
  /// Returns the [UserAuthService] base on the current [AuthType].
  /// Creates a new [AppFlowyServer] if it doesn't exist.
  fn get_auth_service(&self, auth_type: &AuthType) -> Result<Arc<dyn UserAuthService>, FlowyError> {
    server_from_auth_type(auth_type).map(|server| {
      let user_service = server.user_service();
      // self.providers.write().insert(auth_type.clone(), server);
      user_service
    })
  }
}

fn server_from_auth_type(auth_type: &AuthType) -> Result<Arc<dyn AppFlowyServer>, FlowyError> {
  match auth_type {
    AuthType::Local => {
      let server = Arc::new(LocalServer::new());
      Ok(server)
    },
    AuthType::SelfHosted => {
      let config = self_host_server_configuration().map_err(|e| {
        FlowyError::new(
          ErrorCode::InvalidAuthConfig,
          format!("Missing self host config: {:?}. Error: {:?}", auth_type, e),
        )
      })?;
      let server = Arc::new(SelfHostServer::new(config));
      Ok(server)
    },
    AuthType::Supabase => {
      // init the SupabaseServerConfiguration from the environment variables.
      let config = SupabaseServerConfiguration {
        supabase_url: std::env::var(SUPABASE_URL).map_err(|e| {
          FlowyError::new(
            ErrorCode::InvalidAuthConfig,
            format!("Missing SUPABASE_URL: {:?}. Error: {:?}", auth_type, e),
          )
        })?,
        supabase_key: std::env::var(SUPABASE_KEY).map_err(|e| {
          FlowyError::new(
            ErrorCode::InvalidAuthConfig,
            format!("Missing SUPABASE_KEY: {:?}. Error: {:?}", auth_type, e),
          )
        })?,
        supabase_jwt: std::env::var(SUPABASE_JWT).map_err(|e| {
          FlowyError::new(
            ErrorCode::InvalidAuthConfig,
            format!("Missing SUPABASE_JWT: {:?}. Error: {:?}", auth_type, e),
          )
        })?,
      };
      let server = Arc::new(SupabaseServer::new(config));
      Ok(server)
    },
  }
}
