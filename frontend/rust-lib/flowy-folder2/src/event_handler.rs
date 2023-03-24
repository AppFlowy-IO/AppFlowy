use crate::entities::{
  CreateViewPayloadPB, CreateWorkspacePayloadPB, MoveFolderItemPayloadPB, RepeatedAppPB,
  RepeatedTrashIdPB, RepeatedTrashPB, RepeatedViewIdPB, RepeatedWorkspacePB, TrashIdPB,
  UpdateViewPayloadPB, ViewIdPB, ViewPB, WorkspaceIdPB, WorkspacePB, WorkspaceSettingPB,
};
use crate::manager::FolderManager;
use flowy_error::FlowyError;
use lib_dispatch::prelude::{AFPluginData, AFPluginState, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn create_workspace_handler(
  data: AFPluginData<CreateWorkspacePayloadPB>,
  folder_manager: AFPluginState<Arc<FolderManager>>,
) -> DataResult<WorkspacePB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn read_workspace_apps_handler(
  folder_manager: AFPluginState<Arc<FolderManager>>,
) -> DataResult<RepeatedAppPB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn open_workspace_handler(
  data: AFPluginData<WorkspaceIdPB>,
  folder_manager: AFPluginState<Arc<FolderManager>>,
) -> DataResult<WorkspacePB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, folder), err)]
pub(crate) async fn read_workspaces_handler(
  data: AFPluginData<WorkspaceIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<RepeatedWorkspacePB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(folder), err)]
pub async fn read_cur_workspace_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<WorkspaceSettingPB, FlowyError> {
  todo!()
}

pub(crate) async fn create_view_handler(
  data: AFPluginData<CreateViewPayloadPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<ViewPB, FlowyError> {
  todo!()
}

pub(crate) async fn read_view_handler(
  data: AFPluginData<ViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<ViewPB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn update_view_handler(
  data: AFPluginData<UpdateViewPayloadPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

pub(crate) async fn delete_view_handler(
  data: AFPluginData<RepeatedViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

pub(crate) async fn set_latest_view_handler(
  data: AFPluginData<ViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

pub(crate) async fn close_view_handler(
  data: AFPluginData<ViewIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn move_item_handler(
  data: AFPluginData<MoveFolderItemPayloadPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn duplicate_view_handler(
  data: AFPluginData<ViewPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn read_trash_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> DataResult<RepeatedTrashPB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(identifier, controller), err)]
pub(crate) async fn putback_trash_handler(
  identifier: AFPluginData<TrashIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(identifiers, controller), err)]
pub(crate) async fn delete_trash_handler(
  identifiers: AFPluginData<RepeatedTrashIdPB>,
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn restore_all_trash_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(controller), err)]
pub(crate) async fn delete_all_trash_handler(
  folder: AFPluginState<Arc<FolderManager>>,
) -> Result<(), FlowyError> {
  todo!()
}
