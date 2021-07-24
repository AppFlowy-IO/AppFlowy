use crate::{
    entities::{app::RepeatedApp, workspace::*},
    errors::WorkspaceError,
    services::WorkspaceController,
};
use flowy_dispatch::prelude::{response_ok, Data, ResponseResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "create_workspace", skip(data, controller))]
pub async fn create_workspace(
    data: Data<CreateWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> ResponseResult<Workspace, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.create_workspace(params).await?;
    response_ok(detail)
}

#[tracing::instrument(name = "get_cur_workspace", skip(controller))]
pub async fn get_cur_workspace(
    controller: Unit<Arc<WorkspaceController>>,
) -> ResponseResult<Workspace, WorkspaceError> {
    let workspace = controller.read_cur_workspace().await?;
    response_ok(workspace)
}

#[tracing::instrument(name = "get_workspace", skip(data, controller))]
pub async fn get_workspace(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> ResponseResult<Workspace, WorkspaceError> {
    let params: QueryWorkspaceParams = data.into_inner().try_into()?;
    let mut workspace = controller.read_workspace(&params.workspace_id).await?;

    if params.read_apps {
        let apps = controller.read_apps(&params.workspace_id).await?;
        workspace.apps = RepeatedApp { items: apps };
    }

    response_ok(workspace)
}
