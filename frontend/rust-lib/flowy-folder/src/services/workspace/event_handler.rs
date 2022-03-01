use crate::{
    controller::FolderManager,
    dart_notification::{send_dart_notification, FolderNotification},
    errors::FlowyError,
    services::{get_current_workspace, read_local_workspace_apps, WorkspaceController},
};
use flowy_folder_data_model::entities::{
    app::RepeatedApp,
    view::View,
    workspace::{CurrentWorkspaceSetting, RepeatedWorkspace, WorkspaceId, *},
};

use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn create_workspace_handler(
    data: Data<CreateWorkspacePayload>,
    controller: AppData<Arc<WorkspaceController>>,
) -> DataResult<Workspace, FlowyError> {
    let controller = controller.get_ref().clone();
    let params: CreateWorkspaceParams = data.into_inner().try_into()?;
    let detail = controller.create_workspace_from_params(params).await?;
    data_result(detail)
}

#[tracing::instrument(skip(controller), err)]
pub(crate) async fn read_workspace_apps_handler(
    controller: AppData<Arc<WorkspaceController>>,
) -> DataResult<RepeatedApp, FlowyError> {
    let repeated_app = controller.read_current_workspace_apps().await?;
    data_result(repeated_app)
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn open_workspace_handler(
    data: Data<WorkspaceId>,
    controller: AppData<Arc<WorkspaceController>>,
) -> DataResult<Workspace, FlowyError> {
    let params: WorkspaceId = data.into_inner();
    let workspaces = controller.open_workspace(params).await?;
    data_result(workspaces)
}

#[tracing::instrument(skip(data, folder), err)]
pub(crate) async fn read_workspaces_handler(
    data: Data<WorkspaceId>,
    folder: AppData<Arc<FolderManager>>,
) -> DataResult<RepeatedWorkspace, FlowyError> {
    let params: WorkspaceId = data.into_inner();
    let user_id = folder.user.user_id()?;
    let workspace_controller = folder.workspace_controller.clone();

    let trash_controller = folder.trash_controller.clone();
    let workspaces = folder
        .persistence
        .begin_transaction(|transaction| {
            let mut workspaces =
                workspace_controller.read_local_workspaces(params.value.clone(), &user_id, &transaction)?;
            for workspace in workspaces.iter_mut() {
                let apps =
                    read_local_workspace_apps(&workspace.id, trash_controller.clone(), &transaction)?.into_inner();
                workspace.apps.items = apps;
            }
            Ok(workspaces)
        })
        .await?;
    let _ = read_workspaces_on_server(folder, user_id, params);
    data_result(workspaces)
}

#[tracing::instrument(skip(folder), err)]
pub async fn read_cur_workspace_handler(
    folder: AppData<Arc<FolderManager>>,
) -> DataResult<CurrentWorkspaceSetting, FlowyError> {
    let workspace_id = get_current_workspace()?;
    let user_id = folder.user.user_id()?;
    let params = WorkspaceId {
        value: Some(workspace_id.clone()),
    };

    let workspace = folder
        .persistence
        .begin_transaction(|transaction| {
            folder
                .workspace_controller
                .read_local_workspace(workspace_id, &user_id, &transaction)
        })
        .await?;

    let latest_view: Option<View> = folder.view_controller.latest_visit_view().await.unwrap_or(None);
    let setting = CurrentWorkspaceSetting { workspace, latest_view };
    let _ = read_workspaces_on_server(folder, user_id, params);
    data_result(setting)
}

#[tracing::instrument(level = "trace", skip(folder_manager), err)]
fn read_workspaces_on_server(
    folder_manager: AppData<Arc<FolderManager>>,
    user_id: String,
    params: WorkspaceId,
) -> Result<(), FlowyError> {
    let (token, server) = (folder_manager.user.token()?, folder_manager.cloud_service.clone());
    let persistence = folder_manager.persistence.clone();

    tokio::spawn(async move {
        let workspaces = server.read_workspace(&token, params).await?;
        let _ = persistence
            .begin_transaction(|transaction| {
                tracing::trace!("Save {} workspace", workspaces.len());
                for workspace in &workspaces.items {
                    let m_workspace = workspace.clone();
                    let apps = m_workspace.apps.clone().into_inner();
                    let _ = transaction.create_workspace(&user_id, m_workspace)?;
                    tracing::trace!("Save {} apps", apps.len());
                    for app in apps {
                        let views = app.belongings.clone().into_inner();
                        match transaction.create_app(app) {
                            Ok(_) => {}
                            Err(e) => log::error!("create app failed: {:?}", e),
                        }

                        tracing::trace!("Save {} views", views.len());
                        for view in views {
                            match transaction.create_view(view) {
                                Ok(_) => {}
                                Err(e) => log::error!("create view failed: {:?}", e),
                            }
                        }
                    }
                }
                Ok(())
            })
            .await?;

        send_dart_notification(&token, FolderNotification::WorkspaceListUpdated)
            .payload(workspaces)
            .send();
        Result::<(), FlowyError>::Ok(())
    });

    Ok(())
}
