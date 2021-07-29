use crate::{
    entities::{
        app::{
            App,
            CreateAppParams,
            CreateAppRequest,
            DeleteAppParams,
            DeleteAppRequest,
            QueryAppParams,
            QueryAppRequest,
            UpdateAppParams,
            UpdateAppRequest,
        },
        view::RepeatedView,
    },
    errors::WorkspaceError,
    services::{AppController, ViewController},
};
use flowy_dispatch::prelude::{response_ok, Data, ResponseResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "create_app", skip(data, controller))]
pub async fn create_app(
    data: Data<CreateAppRequest>,
    controller: Unit<Arc<AppController>>,
) -> ResponseResult<App, WorkspaceError> {
    let params: CreateAppParams = data.into_inner().try_into()?;
    let detail = controller.create_app(params)?;
    response_ok(detail)
}

#[tracing::instrument(name = "delete_app", skip(data, controller))]
pub async fn delete_app(
    data: Data<DeleteAppRequest>,
    controller: Unit<Arc<AppController>>,
) -> Result<(), WorkspaceError> {
    let params: DeleteAppParams = data.into_inner().try_into()?;
    let _ = controller.delete_app(&params.app_id).await?;
    Ok(())
}

#[tracing::instrument(name = "update_app", skip(data, controller))]
pub async fn update_app(
    data: Data<UpdateAppRequest>,
    controller: Unit<Arc<AppController>>,
) -> Result<(), WorkspaceError> {
    let params: UpdateAppParams = data.into_inner().try_into()?;
    let _ = controller.update_app(params).await?;
    Ok(())
}

#[tracing::instrument(name = "read_app", skip(data, app_controller, view_controller))]
pub async fn read_app(
    data: Data<QueryAppRequest>,
    app_controller: Unit<Arc<AppController>>,
    view_controller: Unit<Arc<ViewController>>,
) -> ResponseResult<App, WorkspaceError> {
    let params: QueryAppParams = data.into_inner().try_into()?;
    let mut app = app_controller
        .read_app(&params.app_id, params.is_trash)
        .await?;
    if params.read_belongings {
        let views = view_controller.read_views_belong_to(&params.app_id).await?;
        app.belongings = RepeatedView { items: views };
    }

    response_ok(app)
}
