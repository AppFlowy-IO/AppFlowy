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
use flowy_folder_data_model::revision::TrashRevision;
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::{convert::TryInto, sync::Arc};

pub(crate) async fn create_view_handler(
    data: Data<CreateViewPayloadPB>,
    controller: AppData<Arc<ViewController>>,
) -> DataResult<ViewPB, FlowyError> {
    let params: CreateViewParams = data.into_inner().try_into()?;
    let view_rev = controller.create_view_from_params(params).await?;
    data_result(view_rev.into())
}

pub(crate) async fn read_view_handler(
    data: Data<ViewIdPB>,
    controller: AppData<Arc<ViewController>>,
) -> DataResult<ViewPB, FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    let view_rev = controller.read_view(view_id.clone()).await?;
    data_result(view_rev.into())
}

pub(crate) async fn read_view_info_handler(
    data: Data<ViewIdPB>,
    controller: AppData<Arc<ViewController>>,
) -> DataResult<ViewInfoPB, FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    let view_info = controller.read_view_info(view_id.clone()).await?;
    data_result(view_info)
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn update_view_handler(
    data: Data<UpdateViewPayloadPB>,
    controller: AppData<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let params: UpdateViewParams = data.into_inner().try_into()?;
    let _ = controller.update_view(params).await?;

    Ok(())
}

pub(crate) async fn delete_view_handler(
    data: Data<RepeatedViewIdPB>,
    view_controller: AppData<Arc<ViewController>>,
    trash_controller: AppData<Arc<TrashController>>,
) -> Result<(), FlowyError> {
    let params: RepeatedViewIdPB = data.into_inner();
    for view_id in &params.items {
        let _ = view_controller.delete_view(view_id.into()).await;
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

    let _ = trash_controller.add(trash).await?;
    Ok(())
}

pub(crate) async fn set_latest_view_handler(
    data: Data<ViewIdPB>,
    folder: AppData<Arc<FolderManager>>,
    controller: AppData<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    let _ = controller.set_latest_view(&view_id.value)?;
    let _ = notify_workspace_setting_did_change(&folder, &view_id).await?;
    Ok(())
}

pub(crate) async fn close_view_handler(
    data: Data<ViewIdPB>,
    controller: AppData<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    let _ = controller.close_view(&view_id.value).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn move_item_handler(
    data: Data<MoveFolderItemPayloadPB>,
    view_controller: AppData<Arc<ViewController>>,
    app_controller: AppData<Arc<AppController>>,
) -> Result<(), FlowyError> {
    let params: MoveFolderItemParams = data.into_inner().try_into()?;
    match params.ty {
        MoveFolderItemType::MoveApp => {
            let _ = app_controller.move_app(&params.item_id, params.from, params.to).await?;
        }
        MoveFolderItemType::MoveView => {
            let _ = view_controller
                .move_view(&params.item_id, params.from, params.to)
                .await?;
        }
    }
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, controller), err)]
pub(crate) async fn duplicate_view_handler(
    data: Data<ViewIdPB>,
    controller: AppData<Arc<ViewController>>,
) -> Result<(), FlowyError> {
    let view_id: ViewIdPB = data.into_inner();
    let _ = controller.duplicate_view(&view_id.value).await?;
    Ok(())
}
