use flowy_dispatch::prelude::Module;
use flowy_user::prelude::*;

use crate::flowy_server::{ArcFlowyServer, MockFlowyServer};
use flowy_database::DBConnection;

use flowy_workspace::prelude::*;
use std::sync::Arc;

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig, _server: ArcFlowyServer) -> Vec<Module> {
    let user_session = Arc::new(
        UserSessionBuilder::new()
            .root_dir(&config.root)
            .build(Arc::new(MockFlowyServer {})),
    );

    let workspace_user_impl = Arc::new(WorkspaceUserImpl {
        user_session: user_session.clone(),
    });

    vec![
        flowy_user::module::create(user_session),
        flowy_workspace::module::create(workspace_user_impl),
    ]
}

pub struct WorkspaceUserImpl {
    user_session: Arc<UserSession>,
}

impl WorkspaceUser for WorkspaceUserImpl {
    fn set_current_workspace(&self, id: &str) { UserSession::set_current_workspace(id); }

    fn get_current_workspace(&self) -> Result<String, WorkspaceError> {
        let user_detail = self.user_session.user_detail().map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::UserNotLoginYet)
                .error(e)
                .build()
        })?;
        Ok(user_detail.id)
    }

    fn db_connection(&self) -> Result<DBConnection, WorkspaceError> {
        self.user_session.get_db_connection().map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::DatabaseConnectionFail)
                .error(e)
                .build()
        })
    }
}
