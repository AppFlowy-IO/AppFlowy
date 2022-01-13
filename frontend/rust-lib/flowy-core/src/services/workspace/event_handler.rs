use crate::{
    context::CoreContext,
    dart_notification::{send_dart_notification, WorkspaceNotification},
    errors::FlowyError,
    services::{
        get_current_workspace,
        read_local_workspace_apps,
        workspace::sql::WorkspaceTableSql,
        WorkspaceController,
    },
};
use flowy_core_data_model::entities::{
    app::RepeatedApp,
    view::View,
    workspace::{CurrentWorkspaceSetting, QueryWorkspaceRequest, RepeatedWorkspace, WorkspaceId, *},
};
use lib_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn create_workspace_handler(
    data: Data<CreateWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, FlowyError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.create_workspace_from_params(params).await?;
    data_result(detail)
}

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn read_workspace_apps_handler(
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<RepeatedApp, FlowyError> {
    let repeated_app = controller.read_current_workspace_apps().await?;
    data_result(repeated_app)
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn open_workspace_handler(
    data: Data<QueryWorkspaceRequest>,
    controller: Unit<Arc<WorkspaceController>>,
) -> DataResult<Workspace, FlowyError> {
    let params: WorkspaceId = data.into_inner().try_into()?;
    let workspaces = controller.open_workspace(params).await?;
    data_result(workspaces)
}

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

#[tracing::instrument(level = "debug", skip(core), err)]
fn read_workspaces_on_server(
    core: Unit<Arc<CoreContext>>,
    user_id: String,
    params: WorkspaceId,
) -> Result<(), FlowyError> {
    let (token, server) = (core.user.token()?, core.cloud_service.clone());
    let app_ctrl = core.app_controller.clone();
    let view_ctrl = core.view_controller.clone();
    let conn = core.database.db_connection()?;

    tokio::spawn(async move {
        // Opti: handle the error and retry?
        let workspaces = server.read_workspace(&token, params).await?;
        let _ = (&*conn).immediate_transaction::<_, FlowyError, _>(|| {
            tracing::debug!("Save {} workspace", workspaces.len());
            for workspace in &workspaces.items {
                let m_workspace = workspace.clone();
                let apps = m_workspace.apps.clone().into_inner();
                let _ = WorkspaceTableSql::create_workspace(&user_id, m_workspace, &*conn)?;
                tracing::debug!("Save {} apps", apps.len());
                for app in apps {
                    let views = app.belongings.clone().into_inner();
                    match app_ctrl.save_app(app, &*conn) {
                        Ok(_) => {},
                        Err(e) => log::error!("create app failed: {:?}", e),
                    }

                    tracing::debug!("Save {} views", views.len());
                    for view in views {
                        match view_ctrl.save_view(view, &*conn) {
                            Ok(_) => {},
                            Err(e) => log::error!("create view failed: {:?}", e),
                        }
                    }
                }
            }
            Ok(())
        })?;

        send_dart_notification(&token, WorkspaceNotification::WorkspaceListUpdated)
            .payload(workspaces)
            .send();
        Result::<(), FlowyError>::Ok(())
    });

    Ok(())
}
