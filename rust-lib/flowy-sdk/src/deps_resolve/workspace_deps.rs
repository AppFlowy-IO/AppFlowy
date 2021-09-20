
use flowy_database::ConnectionPool;
use flowy_user::services::user::UserSession;
use flowy_workspace::{
    errors::WorkspaceError,
    module::{WorkspaceDatabase, WorkspaceUser},
};

use std::sync::Arc;

pub struct WorkspaceDepsResolver {
    inner: Arc<Resolver>,
}

struct Resolver {
    pub(crate) user_session: Arc<UserSession>,
}

impl WorkspaceDepsResolver {
    pub fn new(user_session: Arc<UserSession>) -> Self {
        Self {
            inner: Arc::new(Resolver { user_session }),
        }
    }

    pub fn split_into(self) -> (Arc<dyn WorkspaceUser>, Arc<dyn WorkspaceDatabase>) {
        let user: Arc<dyn WorkspaceUser> = self.inner.clone();
        let database: Arc<dyn WorkspaceDatabase> = self.inner.clone();
        (user, database)
    }
}

impl WorkspaceDatabase for Resolver {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, WorkspaceError> {
        self.user_session.db_pool().map_err(|e| WorkspaceError::internal().context(e))
    }
}

impl WorkspaceUser for Resolver {
    fn user_id(&self) -> Result<String, WorkspaceError> { self.user_session.user_id().map_err(|e| WorkspaceError::internal().context(e)) }

    fn token(&self) -> Result<String, WorkspaceError> { self.user_session.token().map_err(|e| WorkspaceError::internal().context(e)) }
}
