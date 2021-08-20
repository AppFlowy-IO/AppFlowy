use flowy_dispatch::prelude::{
    DispatchError,
    DispatchFuture,
    EventDispatch,
    ModuleRequest,
    ToBytes,
};
use flowy_user::{
    errors::{ErrorBuilder, UserErrCode, UserError},
    prelude::WorkspaceAction,
};
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, Workspace},
    event::WorkspaceEvent::CreateWorkspace,
};

pub struct UserWorkspaceActionImpl {}
impl WorkspaceAction for UserWorkspaceActionImpl {
    fn create_workspace(
        &self,
        name: &str,
        desc: &str,
        _user_id: &str,
    ) -> DispatchFuture<Result<String, UserError>> {
        log::info!("Create user workspace: {:?}", name);
        let payload: Vec<u8> = CreateWorkspaceRequest {
            name: name.to_string(),
            desc: desc.to_string(),
        }
        .into_bytes()
        .unwrap();

        let request = ModuleRequest::new(CreateWorkspace).payload(payload);
        DispatchFuture {
            fut: Box::pin(async move {
                let result = EventDispatch::async_send(request)
                    .await
                    .parse::<Workspace, DispatchError>()
                    .map_err(|e| {
                        ErrorBuilder::new(UserErrCode::CreateDefaultWorkspaceFailed)
                            .error(e)
                            .build()
                    })?;

                let workspace = result.map_err(|e| {
                    ErrorBuilder::new(UserErrCode::CreateDefaultWorkspaceFailed)
                        .error(e)
                        .build()
                })?;
                Ok(workspace.id)
            }),
        }
    }
}
