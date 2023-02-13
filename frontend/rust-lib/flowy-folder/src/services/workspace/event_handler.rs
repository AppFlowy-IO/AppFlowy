use crate::entities::{
  app::RepeatedAppPB,
  view::ViewPB,
  workspace::{RepeatedWorkspacePB, WorkspaceIdPB, WorkspaceSettingPB, *},
};
use crate::{
  errors::FlowyError,
  manager::FolderManager,
  services::{get_current_workspace, read_workspace_apps, WorkspaceController},
};
use lib_dispatch::prelude::{data_result, AFPluginData, AFPluginState, DataResult};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn create_workspace_handler(
  data: AFPluginData<CreateWorkspacePayloadPB>,
  controller: AFPluginState<Arc<WorkspaceController>>,
) -> DataResult<WorkspacePB, FlowyError> {
  let controller = controller.get_ref().clone();
  let params: CreateWorkspaceParams = data.into_inner().try_into()?;
  let workspace_rev = controller.create_workspace_from_params(params).await?;
  data_result(workspace_rev.into())
}

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn read_workspace_apps_handler(
  controller: AFPluginState<Arc<WorkspaceController>>,
) -> DataResult<RepeatedAppPB, FlowyError> {
  let items = controller
    .read_current_workspace_apps()
    .await?
    .into_iter()
    .map(|app_rev| app_rev.into())
    .collect();
  let repeated_app = RepeatedAppPB { items };
  data_result(repeated_app)
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn open_workspace_handler(
  data: AFPluginData<WorkspaceIdPB>,
  controller: AFPluginState<Arc<WorkspaceController>>,
) -> DataResult<WorkspacePB, FlowyError> {
  let params: WorkspaceIdPB = data.into_inner();
  let workspaces = controller.open_workspace(params).await?;
  data_result(workspaces)
}

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn read_workspaces_handler(
  data: AFPluginData<WorkspaceIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<RepeatedWorkspacePB, FlowyError> {
  let params: WorkspaceIdPB = data.into_inner();
  let user_id = folder.user.user_id()?;
  let workspace_controller = folder.workspace_controller.clone();

  let trash_controller = folder.trash_controller.clone();
  let workspaces = folder
    .persistence
    .begin_transaction(|transaction| {
      let mut workspaces =
        workspace_controller.read_workspaces(params.value.clone(), &user_id, &transaction)?;
      for workspace in workspaces.iter_mut() {
        let apps = read_workspace_apps(&workspace.id, trash_controller.clone(), &transaction)?
          .into_iter()
          .map(|app_rev| app_rev.into())
          .collect();
        workspace.apps.items = apps;
      }
      Ok(workspaces)
    })
    .await?;
  data_result(workspaces)
}

#[tracing::instrument(level = "debug", skip(folder), err)]
pub async fn read_cur_workspace_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<WorkspaceSettingPB, FlowyError> {
  let user_id = folder.user.user_id()?;
  let workspace_id = get_current_workspace(&user_id)?;
  let workspace = folder
    .persistence
    .begin_transaction(|transaction| {
      folder
        .workspace_controller
        .read_workspace(workspace_id, &user_id, &transaction)
    })
    .await?;

  let latest_view: Option<ViewPB> = folder
    .view_controller
    .latest_visit_view()
    .await
    .unwrap_or(None)
    .map(|view_rev| view_rev.into());
  let setting = WorkspaceSettingPB {
    workspace,
    latest_view,
  };
  data_result(setting)
}
