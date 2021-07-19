use crate::{
    entities::workspace::{CreateWorkspaceParams, CreateWorkspaceRequest, WorkspaceDetail},
    errors::WorkspaceError,
    services::WorkspaceController,
};
use flowy_dispatch::prelude::{response_ok, Data, ModuleData, ResponseResult};
use std::{convert::TryInto, sync::Arc};

pub async fn create_workspace(
    data: Data<CreateWorkspaceRequest>,
    controller: ModuleData<Arc<WorkspaceController>>,
) -> ResponseResult<WorkspaceDetail, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.save_workspace(params).await?;
    response_ok(detail)
}

pub async fn workspace_user(
    data: Data<CreateWorkspaceRequest>,
    controller: ModuleData<Arc<WorkspaceController>>,
) -> ResponseResult<WorkspaceDetail, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.save_workspace(params).await?;
    response_ok(detail)
}
