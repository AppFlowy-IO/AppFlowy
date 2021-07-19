use flowy_dispatch::prelude::{DispatchFuture, EventDispatch, ModuleRequest, ToBytes};
use flowy_user::{
    entities::{SignInParams, SignUpParams, UserDetail},
    errors::{ErrorBuilder, UserError, UserErrorCode},
    prelude::UserServer,
    sql_tables::UserTable,
};
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, WorkspaceDetail},
    errors::WorkspaceError,
    event::WorkspaceEvent::CreateWorkspace,
};

pub type ArcFlowyServer = std::sync::Arc<dyn FlowyServer>;

pub trait FlowyServer: UserServer {}

pub struct FlowyServerMocker {}

impl FlowyServer for FlowyServerMocker {}

impl UserServer for FlowyServerMocker {
    fn sign_up(&self, params: SignUpParams) -> Result<UserTable, UserError> {
        let user_id = params.email.clone();
        Ok(UserTable::new(
            user_id,
            params.name,
            params.email,
            params.password,
        ))
    }

    fn sign_in(&self, params: SignInParams) -> Result<UserTable, UserError> {
        let user_id = params.email.clone();
        Ok(UserTable::new(
            user_id,
            "".to_owned(),
            params.email,
            params.password,
        ))
    }

    fn sign_out(&self, _user_id: &str) -> Result<(), UserError> {
        Err(ErrorBuilder::new(UserErrorCode::Unknown).build())
    }

    fn get_user_info(&self, _user_id: &str) -> Result<UserDetail, UserError> {
        Err(ErrorBuilder::new(UserErrorCode::Unknown).build())
    }

    fn create_workspace(
        &self,
        name: &str,
        desc: &str,
        _user_id: &str,
    ) -> DispatchFuture<Result<(), UserError>> {
        let payload: Vec<u8> = CreateWorkspaceRequest {
            name: name.to_string(),
            desc: desc.to_string(),
        }
        .into_bytes()
        .unwrap();

        let request = ModuleRequest::new(CreateWorkspace).payload(payload);
        DispatchFuture {
            fut: Box::pin(async move {
                let _ = EventDispatch::async_send(request)
                    .await
                    .parse::<WorkspaceDetail, WorkspaceError>()
                    .map_err(|e| {
                        ErrorBuilder::new(UserErrorCode::CreateDefaultWorkspaceFailed)
                            .error(e)
                            .build()
                    })?;
                Ok(())
            }),
        }
    }
}
