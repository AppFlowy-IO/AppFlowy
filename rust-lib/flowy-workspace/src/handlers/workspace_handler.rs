use crate::{
    entities::workspace::{
        CreateWorkspaceParams,
        CreateWorkspaceRequest,
        UserWorkspace,
        UserWorkspaceDetail,
        Workspace,
    },
    errors::WorkspaceError,
    services::WorkspaceController,
};
use flowy_dispatch::prelude::{response_ok, Data, ModuleData, ResponseResult};
use std::{convert::TryInto, sync::Arc};

pub async fn create_workspace(
    data: Data<CreateWorkspaceRequest>,
    controller: ModuleData<Arc<WorkspaceController>>,
) -> ResponseResult<Workspace, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.save_workspace(params).await?;
    response_ok(detail)
}

pub async fn get_workspace_detail(
    controller: ModuleData<Arc<WorkspaceController>>,
) -> ResponseResult<UserWorkspaceDetail, WorkspaceError> {
    let user_workspace = controller.get_user_workspace_detail().await?;
    response_ok(user_workspace)
}
