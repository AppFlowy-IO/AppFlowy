use flowy_database::DBConnection;

use flowy_user::prelude::UserSession;
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
    fn db_connection(&self) -> Result<DBConnection, WorkspaceError> {
        self.user_session
            .db_conn()
            .map_err(|e| ErrorBuilder::new(ErrorCode::DatabaseConnectionFail).error(e).build())
    }
}
