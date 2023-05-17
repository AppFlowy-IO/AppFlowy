use std::sync::Arc;

use flowy_net::http_server::self_host::configuration::ClientServerConfiguration;
use flowy_net::http_server::self_host::user::UserHttpCloudService;
use flowy_net::local_server::LocalServer;
use flowy_user::event_map::UserCloudService;

pub struct UserDepsResolver();
impl UserDepsResolver {
  pub fn resolve(
    local_server: &Option<Arc<LocalServer>>,
    server_config: &ClientServerConfiguration,
  ) -> Arc<dyn UserCloudService> {
    match local_server.clone() {
      None => Arc::new(UserHttpCloudService::new(server_config)),
      Some(local_server) => local_server,
    }
  }
}
