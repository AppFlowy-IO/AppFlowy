use crate::entities::{
  AppPB, CreateViewParams, CreateViewPayloadPB, CreateWorkspaceParams, CreateWorkspacePayloadPB,
  MoveFolderItemParams, MoveFolderItemPayloadPB, RepeatedAppPB, RepeatedTrashIdPB, RepeatedTrashPB,
  RepeatedViewIdPB, RepeatedViewPB, RepeatedWorkspacePB, TrashIdPB, UpdateViewParams,
  UpdateViewPayloadPB, ViewIdPB, ViewPB, WorkspaceIdPB, WorkspacePB, WorkspaceSettingPB,
};
use crate::manager::FolderManager;
use flowy_error::FlowyError;
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn create_workspace_handler(
  data: AFPluginData<CreateWorkspacePayloadPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<WorkspacePB, FlowyError> {
  let params: CreateWorkspaceParams = data.into_inner().try_into()?;
  let workspace = folder.create_workspace(params).await?;
  data_result_ok(workspace.into())
}

#[tracing::instrument(level = "debug", skip(folder), err)]
pub(crate) async fn read_workspace_apps_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<RepeatedAppPB, FlowyError> {
  let views = folder.get_workspace_views().await?;
  let mut repeated_app = RepeatedAppPB { items: vec![] };
  for view in views.into_iter() {
    let child_views = folder.get_views_belong_to(&view.id).await?;
    repeated_app.items.push(AppPB {
      id: view.id,
      workspace_id: view.bid,
      name: view.name,
      belongings: child_views.into(),
      create_time: view.created_at,
    })
  }
  data_result_ok(repeated_app)
}

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn open_workspace_handler(
  data: AFPluginData<WorkspaceIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<WorkspacePB, FlowyError> {
  let params: WorkspaceIdPB = data.into_inner();
  match params.value {
    None => Err(FlowyError::workspace_id().context("workspace id should not be empty")),
    Some(workspace_id) => {
      let workspace = folder.open_workspace(&workspace_id).await?;
      let workspace_pb: WorkspacePB = workspace.into();
      data_result_ok(workspace_pb)
    },
  }
}

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn read_workspaces_handler(
  data: AFPluginData<WorkspaceIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<RepeatedWorkspacePB, FlowyError> {
  let params: WorkspaceIdPB = data.into_inner();
  let workspaces = match params.value {
    None => folder.get_all_workspaces().await,
    Some(workspace_id) => folder
      .get_workspace(&workspace_id)
      .await
      .map(|workspace| vec![workspace])
      .unwrap_or_default(),
  };
  data_result_ok(workspaces.into())
}

#[tracing::instrument(level = "debug", skip(folder), err)]
pub async fn read_cur_workspace_setting_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<WorkspaceSettingPB, FlowyError> {
  let workspace: WorkspacePB = folder.get_current_workspace().await?.into();
  let latest_view: Option<ViewPB> = folder.get_current_view().await.map(|view| view.into());
  data_result_ok(WorkspaceSettingPB {
    workspace,
    latest_view,
  })
}

pub(crate) async fn create_view_handler(
  data: AFPluginData<CreateViewPayloadPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<ViewPB, FlowyError> {
  let params: CreateViewParams = data.into_inner().try_into()?;
  let view = folder.create_view_with_params(params).await?;
  data_result_ok(view.into())
}

pub(crate) async fn read_view_handler(
  data: AFPluginData<ViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<ViewPB, FlowyError> {
  let view_id: ViewIdPB = data.into_inner();
  let view = folder.get_view(&view_id.value).await?;
  data_result_ok(view.into())
}

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn update_view_handler(
  data: AFPluginData<UpdateViewPayloadPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  let params: UpdateViewParams = data.into_inner().try_into()?;
  let _ = folder.update_view_with_params(params).await?;
  Ok(())
}

pub(crate) async fn delete_view_handler(
  data: AFPluginData<RepeatedViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  let params: RepeatedViewIdPB = data.into_inner();
  for view_id in &params.items {
    folder.move_view_to_trash(view_id);
  }
  Ok(())
}

pub(crate) async fn set_latest_view_handler(
  data: AFPluginData<ViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  let view_id: ViewIdPB = data.into_inner();
  let _ = folder.set_current_view(&view_id.value);
  Ok(())
}

pub(crate) async fn close_view_handler(
  data: AFPluginData<ViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  let view_id: ViewIdPB = data.into_inner();
  folder.close_view(&view_id.value);
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn move_item_handler(
  data: AFPluginData<MoveFolderItemPayloadPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  let params: MoveFolderItemParams = data.into_inner().try_into()?;
  folder
    .move_view(&params.item_id, params.from, params.to)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn duplicate_view_handler(
  data: AFPluginData<ViewPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  let view: ViewPB = data.into_inner();
  folder.duplicate_view(&view.id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(folder), err)]
pub(crate) async fn read_trash_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<RepeatedTrashPB, FlowyError> {
  let trash = folder.get_all_trash().await;
  data_result_ok(trash.into())
}

#[tracing::instrument(level = "debug", skip(identifier, folder), err)]
pub(crate) async fn putback_trash_handler(
  identifier: AFPluginData<TrashIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  folder.restore_trash(&identifier.id);
  Ok(())
}

#[tracing::instrument(level = "debug", skip(identifiers, folder), err)]
pub(crate) async fn delete_trash_handler(
  identifiers: AFPluginData<RepeatedTrashIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  let trash_ids = identifiers.into_inner().items;
  for trash_id in trash_ids {
    folder.delete_trash(&trash_id.id);
  }
  Ok(())
}

#[tracing::instrument(level = "debug", skip(folder), err)]
pub(crate) async fn restore_all_trash_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  folder.restore_all_trash();
  Ok(())
}

#[tracing::instrument(level = "debug", skip(folder), err)]
pub(crate) async fn delete_all_trash_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  folder.delete_all_trash();
  Ok(())
}
