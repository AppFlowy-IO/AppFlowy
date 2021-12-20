use flowy_core::{
    errors::FlowyError,
    module::{WorkspaceDatabase, WorkspaceUser},
};
use flowy_database::ConnectionPool;
use flowy_user::services::user::UserSession;
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
        let database: Arc<dyn WorkspaceDatabase> = self.inner;
        (user, database)
    }
}

impl WorkspaceDatabase for Resolver {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
        self.user_session
            .db_pool()
            .map_err(|e| FlowyError::internal().context(e))
    }
}

impl WorkspaceUser for Resolver {
    fn user_id(&self) -> Result<String, FlowyError> {
        self.user_session
            .user_id()
            .map_err(|e| FlowyError::internal().context(e))
    }

    fn token(&self) -> Result<String, FlowyError> {
        self.user_session.token().map_err(|e| FlowyError::internal().context(e))
    }
}
