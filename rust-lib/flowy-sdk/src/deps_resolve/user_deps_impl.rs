use bytes::Bytes;
use flowy_dispatch::prelude::{
    DispatchError,
    DispatchFuture,
    EventDispatch,
    ModuleRequest,
    ToBytes,
};
use flowy_user::{
    errors::{ErrorBuilder, UserErrCode, UserError},
    prelude::UserWorkspaceController,
};
use flowy_workspace::{
    entities::workspace::{CreateWorkspaceRequest, Workspace},
    event::WorkspaceEvent::CreateWorkspace,
};

pub struct UserWorkspaceControllerImpl {}
impl UserWorkspaceController for UserWorkspaceControllerImpl {
    fn create_workspace(
        &self,
        name: &str,
        desc: &str,
        user_id: &str,
    ) -> DispatchFuture<Result<String, UserError>> {
        log::info!("Create new workspace: {:?}", name);
        let payload: Bytes = CreateWorkspaceRequest {
            name: name.to_string(),
            desc: desc.to_string(),
            user_id: user_id.to_string(),
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
