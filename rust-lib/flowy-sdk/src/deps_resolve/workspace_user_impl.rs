use flowy_database::DBConnection;
use flowy_dispatch::prelude::DispatchFuture;
use flowy_user::prelude::UserSession;
use flowy_workspace::{
    entities::workspace::UserWorkspace,
    errors::{ErrorBuilder, WorkspaceError, WorkspaceErrorCode},
    module::WorkspaceUser,
};
use std::sync::Arc;

pub struct WorkspaceUserImpl {
    pub(crate) user_session: Arc<UserSession>,
}

impl WorkspaceUser for WorkspaceUserImpl {
    fn set_cur_workspace_id(
        &self,
        workspace_id: &str,
    ) -> DispatchFuture<Result<(), WorkspaceError>> {
        let user_session = self.user_session.clone();
        let workspace_id = workspace_id.to_owned();
        DispatchFuture {
            fut: Box::pin(async move {
                let _ = user_session
                    .set_current_workspace(&workspace_id)
                    .await
                    .map_err(|e| {
                        ErrorBuilder::new(WorkspaceErrorCode::UserInternalError)
                            .error(e)
                            .build()
                    });

                Ok(())
            }),
        }
    }

    fn get_cur_workspace(&self) -> DispatchFuture<Result<UserWorkspace, WorkspaceError>> {
        let user_session = self.user_session.clone();
        DispatchFuture {
            fut: Box::pin(async move {
                let user_detail = user_session.user_detail().map_err(|e| {
                    ErrorBuilder::new(WorkspaceErrorCode::UserNotLoginYet)
                        .error(e)
                        .build()
                })?;

                Ok(UserWorkspace {
                    owner: user_detail.email,
                    workspace_id: user_detail.workspace,
                })
            }),
        }
    }

    fn db_connection(&self) -> Result<DBConnection, WorkspaceError> {
        self.user_session.get_db_connection().map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::DatabaseConnectionFail)
                .error(e)
                .build()
        })
    }
}
