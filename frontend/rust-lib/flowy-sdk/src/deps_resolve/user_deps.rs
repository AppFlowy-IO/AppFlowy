use backend_service::configuration::ClientServerConfiguration;
use flowy_net::{http_server::user::UserHttpCloudService, local_server::LocalServer};
use flowy_user::module::UserCloudService;

use std::sync::Arc;

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
