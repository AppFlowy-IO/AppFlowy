use crate::{
    entities::workspace::*,
    errors::{ErrorBuilder, ErrorCode, WorkspaceError},
    services::WorkspaceController,
};
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "create_workspace", skip(data, controller))]
pub(crate) async fn create_workspace(
    data: Data<CreateWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.create_workspace(params).await?;
    data_result(detail)
}

#[tracing::instrument(name = "read_cur_workspace", skip(controller))]
pub(crate) async fn read_cur_workspace(controller: Unit<Arc<WorkspaceController>>) -> DataResult<Workspace, WorkspaceError> {
    let workspace = controller.read_cur_workspace().await?;
    data_result(workspace)
}

#[tracing::instrument(name = "read_workspace", skip(data, controller))]
pub(crate) async fn read_workspaces(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<RepeatedWorkspace, WorkspaceError> {
    let params: QueryWorkspaceParams = data.into_inner().try_into()?;
    let workspaces = controller.read_workspaces(params).await?;
    data_result(workspaces)
}

#[tracing::instrument(name = "open_workspace", skip(data, controller))]
pub(crate) async fn open_workspace(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let params: QueryWorkspaceParams = data.into_inner().try_into()?;
    match params.workspace_id {
        None => Err(ErrorBuilder::new(ErrorCode::WorkspaceIdInvalid).build()),
        Some(workspace_id) => {
            let workspaces = controller.open_workspace(&workspace_id).await?;
            data_result(workspaces)
        },
    }
}
