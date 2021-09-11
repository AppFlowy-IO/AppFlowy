use flowy_database::ConnectionPool;
use flowy_user::services::user::UserSession;
use flowy_workspace::{
    errors::{ErrorBuilder, ErrorCode, WorkspaceError},
    module::{WorkspaceDatabase, WorkspaceUser},
};
use std::sync::Arc;

pub struct WorkspaceUserImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl WorkspaceUser for WorkspaceUserImpl {
    fn user_id(&self) -> Result<String, WorkspaceError> {
        self.user_session
            .user_id()
            .map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())
    }

    fn token(&self) -> Result<String, WorkspaceError> {
        self.user_session
            .token()
            .map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())
    }
}

pub struct WorkspaceDatabaseImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl WorkspaceDatabase for WorkspaceDatabaseImpl {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, WorkspaceError> {
        self.user_session
            .db_pool()
            .map_err(|e| ErrorBuilder::new(ErrorCode::InternalError).error(e).build())
    }
}
