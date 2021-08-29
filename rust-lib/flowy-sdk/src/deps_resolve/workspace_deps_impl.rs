use flowy_database::DBConnection;

use flowy_user::prelude::UserSession;
use flowy_workspace::{
    errors::{ErrorBuilder, WorkspaceError, WsErrCode},
    module::{WorkspaceDatabase, WorkspaceUser},
};
use std::sync::Arc;

pub struct WorkspaceUserImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl WorkspaceUser for WorkspaceUserImpl {
    fn user_id(&self) -> Result<String, WorkspaceError> {
        self.user_session.user_id().map_err(|e| {
            ErrorBuilder::new(WsErrCode::UserInternalError)
                .error(e)
                .build()
        })
    }
}

pub struct WorkspaceDatabaseImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl WorkspaceDatabase for WorkspaceDatabaseImpl {
    fn db_connection(&self) -> Result<DBConnection, WorkspaceError> {
        self.user_session.get_db_connection().map_err(|e| {
            ErrorBuilder::new(WsErrCode::DatabaseConnectionFail)
                .error(e)
                .build()
        })
    }
}
