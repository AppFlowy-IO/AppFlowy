use crate::{
    entities::{
        app::{App, AppId, CreateAppParams, CreateAppPayload, UpdateAppParams, UpdateAppPayload},
        trash::Trash,
    },
    errors::FlowyError,
    services::{AppController, TrashController, ViewController},
};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::{convert::TryInto, sync::Arc};

pub(crate) async fn create_app_handler(
    data: Data<CreateAppPayload>,
    controller: AppData<Arc<AppController>>,
) -> DataResult<App, FlowyError> {
    let params: CreateAppParams = data.into_inner().try_into()?;
    let detail = controller.create_app_from_params(params).await?;

    data_result(detail)
}

pub(crate) async fn delete_app_handler(
    data: Data<AppId>,
    app_controller: AppData<Arc<AppController>>,
    trash_controller: AppData<Arc<TrashController>>,
) -> Result<(), FlowyError> {
    let params: AppId = data.into_inner();
    let trash = app_controller
        .read_local_apps(vec![params.value])
        .await?
        .into_iter()
        .map(|app| app.into())
        .collect::<Vec<Trash>>();

    let _ = trash_controller.add(trash).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, controller))]
pub(crate) async fn update_app_handler(
    data: Data<UpdateAppPayload>,
    controller: AppData<Arc<AppController>>,
) -> Result<(), FlowyError> {
    let params: UpdateAppParams = data.into_inner().try_into()?;
    let _ = controller.update_app(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, app_controller, view_controller))]
pub(crate) async fn read_app_handler(
    data: Data<AppId>,
    app_controller: AppData<Arc<AppController>>,
    view_controller: AppData<Arc<ViewController>>,
) -> DataResult<App, FlowyError> {
    let params: AppId = data.into_inner();
    let mut app = app_controller.read_app(params.clone()).await?;
    app.belongings = view_controller.read_views_belong_to(&params.value).await?;

    data_result(app)
}
