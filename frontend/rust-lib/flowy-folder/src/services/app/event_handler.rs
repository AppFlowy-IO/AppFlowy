use crate::{
    entities::app::{AppIdPB, AppPB, CreateAppParams, CreateAppPayloadPB, UpdateAppParams, UpdateAppPayloadPB},
    errors::FlowyError,
    services::{AppController, TrashController, ViewController},
};
use folder_rev_model::TrashRevision;
use lib_dispatch::prelude::{data_result, AFPluginData, AFPluginState, DataResult};
use std::{convert::TryInto, sync::Arc};

pub(crate) async fn create_app_handler(
    data: AFPluginData<CreateAppPayloadPB>,
    controller: AFPluginState<Arc<AppController>>,
) -> DataResult<AppPB, FlowyError> {
    let params: CreateAppParams = data.into_inner().try_into()?;
    let detail = controller.create_app_from_params(params).await?;

    data_result(detail)
}

pub(crate) async fn delete_app_handler(
    data: AFPluginData<AppIdPB>,
    app_controller: AFPluginState<Arc<AppController>>,
    trash_controller: AFPluginState<Arc<TrashController>>,
) -> Result<(), FlowyError> {
    let params: AppIdPB = data.into_inner();
    let trash = app_controller
        .read_local_apps(vec![params.value])
        .await?
        .into_iter()
        .map(|app_rev| app_rev.into())
        .collect::<Vec<TrashRevision>>();

    let _ = trash_controller.add(trash).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, controller))]
pub(crate) async fn update_app_handler(
    data: AFPluginData<UpdateAppPayloadPB>,
    controller: AFPluginState<Arc<AppController>>,
) -> Result<(), FlowyError> {
    let params: UpdateAppParams = data.into_inner().try_into()?;
    let _ = controller.update_app(params).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, app_controller, view_controller), err)]
pub(crate) async fn read_app_handler(
    data: AFPluginData<AppIdPB>,
    app_controller: AFPluginState<Arc<AppController>>,
    view_controller: AFPluginState<Arc<ViewController>>,
) -> DataResult<AppPB, FlowyError> {
    let params: AppIdPB = data.into_inner();
    let mut app_rev = app_controller.read_app(params.clone()).await?;
    app_rev.belongings = view_controller.read_views_belong_to(&params.value).await?;

    data_result(app_rev.into())
}
