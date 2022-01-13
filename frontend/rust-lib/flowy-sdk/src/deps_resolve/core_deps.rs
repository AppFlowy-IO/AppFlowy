use backend_service::configuration::ClientServerConfiguration;
use flowy_core::{
    errors::FlowyError,
    module::{WorkspaceCloudService, WorkspaceDatabase, WorkspaceUser},
};
use flowy_database::ConnectionPool;
use flowy_net::{http_server::core::CoreHttpCloudService, local_server::LocalServer};
use flowy_user::services::UserSession;

use std::sync::Arc;

pub struct CoreDepsResolver();
impl CoreDepsResolver {
    pub fn resolve(
        local_server: Option<Arc<LocalServer>>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
    ) -> (
        Arc<dyn WorkspaceUser>,
        Arc<dyn WorkspaceDatabase>,
        Arc<dyn WorkspaceCloudService>,
    ) {
        let user: Arc<dyn WorkspaceUser> = Arc::new(WorkspaceUserImpl(user_session.clone()));
        let database: Arc<dyn WorkspaceDatabase> = Arc::new(WorkspaceDatabaseImpl(user_session));
        let cloud_service: Arc<dyn WorkspaceCloudService> = match local_server {
            None => Arc::new(CoreHttpCloudService::new(server_config.clone())),
            Some(local_server) => local_server,
        };
        (user, database, cloud_service)
    }
}

struct WorkspaceDatabaseImpl(Arc<UserSession>);
impl WorkspaceDatabase for WorkspaceDatabaseImpl {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
        self.0.db_pool().map_err(|e| FlowyError::internal().context(e))
    }
}

struct WorkspaceUserImpl(Arc<UserSession>);
impl WorkspaceUser for WorkspaceUserImpl {
    fn user_id(&self) -> Result<String, FlowyError> { self.0.user_id().map_err(|e| FlowyError::internal().context(e)) }

    fn token(&self) -> Result<String, FlowyError> { self.0.token().map_err(|e| FlowyError::internal().context(e)) }
}
