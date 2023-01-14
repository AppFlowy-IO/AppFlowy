use crate::entities::view::{MoveFolderItemParams, MoveFolderItemPayloadPB, MoveFolderItemType};
use crate::entities::ViewInfoPB;
use crate::manager::FolderManager;
use crate::services::{notify_workspace_setting_did_change, AppController};
use crate::{
    entities::{
        trash::TrashPB,
        view::{
            CreateViewParams, CreateViewPayloadPB, RepeatedViewIdPB, UpdateViewParams, UpdateViewPayloadPB, ViewIdPB,
            ViewPB,
        },
    },
    errors::FlowyError,
    services::{TrashController, ViewController},
};
use folder_rev_model::TrashRevision;
use lib_dispatch::prelude::{data_result, AFPluginData, AFPluginState, DataResult};
use std::{convert::TryInto, sync::Arc};

pub(crate) async fn create_view_handler(
    data: AFPluginData<CreateViewPayloadPB>,
    controller: AFPluginState<Arc<ViewController>>,
) -> DataResult<ViewPB, FlowyError> {
    let params: CreateViewParams = data.into_inner().try_into()?;
    let view_rev = controller.create_view_from_params(params).await?;
    data_result(view_rev.into())
}

pub(crate) async fn read_view_handler(
    data: AFPluginData<ViewIdPB>,
    controller: AFPluginState<Arc<ViewController>>,
) -> DataResult<ViewPB, FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    let view_rev = controller.read_view(&view_id.value).await?;
    data_result(view_rev.into())
}

pub(crate) async fn read_view_info_handler(
    data: AFPluginData<ViewIdPB>,
    controller: AFPluginState<Arc<ViewController>>,
) -> DataResult<ViewInfoPB, FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    let view_info = controller.read_view_pb(view_id.clone()).await?;
    data_result(view_info)
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn update_view_handler(
    data: AFPluginData<UpdateViewPayloadPB>,
    controller: AFPluginState<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let params: UpdateViewParams = data.into_inner().try_into()?;
    let _ = controller.update_view(params).await?;

    Ok(())
}

pub(crate) async fn delete_view_handler(
    data: AFPluginData<RepeatedViewIdPB>,
    view_controller: AFPluginState<Arc<ViewController>>,
    trash_controller: AFPluginState<Arc<TrashController>>,
) -> Result<(), FlowyError> {
    let params: RepeatedViewIdPB = data.into_inner();
    for view_id in &params.items {
        let _ = view_controller.move_view_to_trash(view_id.into()).await;
    }

    let trash = view_controller
        .read_local_views(params.items)
        .await?
        .into_iter()
        .map(|view| {
            let trash_rev: TrashRevision = view.into();
            trash_rev.into()
        })
        .collect::<Vec<TrashPB>>();

    trash_controller.add(trash).await?;
    Ok(())
}

pub(crate) async fn set_latest_view_handler(
    data: AFPluginData<ViewIdPB>,
    folder: AFPluginState<Arc<FolderManager>>,
    controller: AFPluginState<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    controller.set_latest_view(&view_id.value)?;
    notify_workspace_setting_did_change(&folder, &view_id).await?;
    Ok(())
}

pub(crate) async fn close_view_handler(
    data: AFPluginData<ViewIdPB>,
    controller: AFPluginState<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    controller.close_view(&view_id.value).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn move_item_handler(
    data: AFPluginData<MoveFolderItemPayloadPB>,
    view_controller: AFPluginState<Arc<ViewController>>,
    app_controller: AFPluginState<Arc<AppController>>,
) -> Result<(), FlowyError> {
    let params: MoveFolderItemParams = data.into_inner().try_into()?;
    match params.ty {
        MoveFolderItemType::MoveApp => {
            app_controller.move_app(&params.item_id, params.from, params.to).await?;
        }
        MoveFolderItemType::MoveView => {
            view_controller
                .move_view(&params.item_id, params.from, params.to)
                .await?;
        }
    }
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn duplicate_view_handler(
    data: AFPluginData<ViewPB>,
    controller: AFPluginState<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let view: ViewPB = data.into_inner();
    controller.duplicate_view(view).await?;
    Ok(())
}
