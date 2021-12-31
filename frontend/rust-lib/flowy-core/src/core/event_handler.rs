use crate::{
    core::{aggregate_tasks::read_workspaces_on_server, CoreContext},
    errors::FlowyError,
    services::{get_current_workspace, read_local_workspace_apps},
};
use flowy_core_data_model::entities::{
    view::View,
    workspace::{CurrentWorkspaceSetting, QueryWorkspaceRequest, RepeatedWorkspace, WorkspaceId},
};
use lib_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(data, core), err)]
pub(crate) async fn read_workspaces_handler(
    data: Data<QueryWorkspaceRequest>,
    core: Unit<Arc<CoreContext>>,
) -> DataResult<RepeatedWorkspace, FlowyError> {
    let params: WorkspaceId = data.into_inner().try_into()?;
    let user_id = core.user.user_id()?;
    let conn = &*core.database.db_connection()?;
    let workspace_controller = core.workspace_controller.clone();

    let trash_controller = core.trash_controller.clone();
    let workspaces = conn.immediate_transaction::<_, FlowyError, _>(|| {
        let mut workspaces = workspace_controller.read_local_workspaces(params.workspace_id.clone(), &user_id, conn)?;
        for workspace in workspaces.iter_mut() {
            let apps = read_local_workspace_apps(&workspace.id, trash_controller.clone(), conn)?.into_inner();
            workspace.apps.items = apps;
        }
        Ok(workspaces)
    })?;

    let _ = read_workspaces_on_server(core, user_id, params);

    data_result(workspaces)
}

#[tracing::instrument(skip(core), err)]
pub async fn read_cur_workspace_handler(
    core: Unit<Arc<CoreContext>>,
) -> DataResult<CurrentWorkspaceSetting, FlowyError> {
    let workspace_id = get_current_workspace()?;
    let user_id = core.user.user_id()?;
    let params = WorkspaceId {
        workspace_id: Some(workspace_id.clone()),
    };
    let conn = &*core.database.db_connection()?;
    let workspace = core
        .workspace_controller
        .read_local_workspace(workspace_id, &user_id, conn)?;

    let latest_view: Option<View> = core.view_controller.latest_visit_view().unwrap_or(None);
    let setting = CurrentWorkspaceSetting { workspace, latest_view };
    let _ = read_workspaces_on_server(core, user_id, params);
    data_result(setting)
}
