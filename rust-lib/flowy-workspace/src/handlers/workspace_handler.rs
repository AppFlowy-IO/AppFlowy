use crate::{
    entities::{app::RepeatedApp, workspace::*},
    errors::{ErrorBuilder, WorkspaceError, WsErrCode},
    services::WorkspaceController,
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "create_workspace", skip(data, controller))]
pub async fn create_workspace(
    data: Data<CreateWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.create_workspace(params).await?;
    data_result(detail)
}

#[tracing::instrument(name = "read_cur_workspace", skip(controller))]
pub async fn read_cur_workspace(
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let workspace = controller.read_cur_workspace().await?;
    data_result(workspace)
}

#[tracing::instrument(name = "read_workspace", skip(data, controller))]
pub async fn read_workspace(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<RepeatedWorkspace, WorkspaceError> {
    let params: QueryWorkspaceParams = data.into_inner().try_into()?;

    let workspaces = controller.read_workspaces(params.workspace_id).await?;

    data_result(workspaces)
}

#[tracing::instrument(name = "open_workspace", skip(data, controller))]
pub async fn open_workspace(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let params: QueryWorkspaceParams = data.into_inner().try_into()?;
    match params.workspace_id {
        None => Err(ErrorBuilder::new(WsErrCode::WorkspaceIdInvalid).build()),
        Some(workspace_id) => {
            let workspaces = controller.open_workspace(&workspace_id).await?;
            data_result(workspaces)
        },
    }
}

#[tracing::instrument(name = "get_all_workspaces", skip(controller))]
pub async fn read_all_workspaces(
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<RepeatedWorkspace, WorkspaceError> {
    let workspaces = controller.read_workspaces_belong_to_user().await?;

    data_result(RepeatedWorkspace { items: workspaces })
}
