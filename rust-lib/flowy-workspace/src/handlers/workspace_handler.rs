use crate::{
    errors::WorkspaceError,
    services::{AppController, ViewController, WorkspaceController},
};
use chrono::Utc;
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use flowy_workspace_infra::{
    entities::{app::RepeatedApp, workspace::*},
    user_default,
};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn init_workspace_handler(controller: Unit<Arc<WorkspaceController>>) -> Result<(), WorkspaceError> {
    let _ = controller.init()?;
    Ok(())
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn create_workspace_handler(
    data: Data<CreateWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.create_workspace_from_params(params).await?;
    data_result(detail)
}

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn read_cur_workspace_handler(
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let workspace = controller.read_current_workspace().await?;
    data_result(workspace)
}

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn read_workspace_apps_handler(
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<RepeatedApp, WorkspaceError> {
    let repeated_app = controller.read_current_workspace_apps().await?;
    data_result(repeated_app)
}

#[tracing::instrument(skip(workspace_controller, app_controller, view_controller), err)]
pub(crate) async fn create_default_workspace_handler(
    workspace_controller: Unit<Arc<WorkspaceController>>,
    app_controller: Unit<Arc<AppController>>,
    view_controller: Unit<Arc<ViewController>>,
) -> DataResult<WorkspaceIdentifier, WorkspaceError> {
    let time = Utc::now();
    let mut workspace = user_default::create_default_workspace(time);
    let workspace_id = workspace.id.clone();
    let apps = workspace.take_apps().into_inner();

    let _ = workspace_controller.create_workspace(workspace).await?;
    for mut app in apps {
        let views = app.take_belongings().into_inner();
        let _ = app_controller.create_app(app).await?;
        for view in views {
            let _ = view_controller.create_view(view).await?;
        }
    }

    data_result(WorkspaceIdentifier {
        workspace_id: Some(workspace_id),
    })
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn read_workspaces_handler(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<RepeatedWorkspace, WorkspaceError> {
    let params: WorkspaceIdentifier = data.into_inner().try_into()?;
    let workspaces = controller.read_workspaces(params).await?;
    data_result(workspaces)
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn open_workspace_handler(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, WorkspaceError> {
    let params: WorkspaceIdentifier = data.into_inner().try_into()?;
    let workspaces = controller.open_workspace(params).await?;
    data_result(workspaces)
}
