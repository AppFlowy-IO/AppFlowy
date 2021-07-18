use crate::flowy_server::{ArcFlowyServer, FlowyServerMocker};
use flowy_database::DBConnection;
use flowy_dispatch::prelude::Module;
use flowy_user::{errors::UserError, prelude::*};
use flowy_workspace::prelude::*;
use futures_core::future::BoxFuture;
use std::{pin::Pin, sync::Arc};

pub struct ModuleConfig {
    pub root: String,
}

pub fn build_modules(config: ModuleConfig, _server: ArcFlowyServer) -> Vec<Module> {
    let user_session = Arc::new(
        UserSessionBuilder::new()
            .root_dir(&config.root)
            .build(Arc::new(FlowyServerMocker {})),
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
    fn set_current_workspace(&self, workspace_id: &str) -> BoxFuture<()> {
        let user_session = self.user_session.clone();
        let workspace_id = workspace_id.to_owned();
        Box::pin(async move {
            match user_session.set_current_workspace(&workspace_id).await {
                Ok(_) => {},
                Err(e) => {
                    log::error!("Set current workspace error: {:?}", e);
                },
            }
        })
    }

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
