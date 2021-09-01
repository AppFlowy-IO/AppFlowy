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
use flowy_dispatch::prelude::{data_result, Data, DataResult, Unit};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "create_app", skip(data, controller))]
pub(crate) async fn create_app(data: Data<CreateAppRequest>, controller: Unit<Arc<AppController>>) -> DataResult<App, WorkspaceError> {
    let params: CreateAppParams = data.into_inner().try_into()?;
    let detail = controller.create_app(params)?;
    data_result(detail)
}

#[tracing::instrument(name = "delete_app", skip(data, controller))]
pub(crate) async fn delete_app(data: Data<DeleteAppRequest>, controller: Unit<Arc<AppController>>) -> Result<(), WorkspaceError> {
    let params: DeleteAppParams = data.into_inner().try_into()?;
    let _ = controller.delete_app(&params.app_id).await?;
    Ok(())
}

#[tracing::instrument(name = "update_app", skip(data, controller))]
pub(crate) async fn update_app(data: Data<UpdateAppRequest>, controller: Unit<Arc<AppController>>) -> Result<(), WorkspaceError> {
    let params: UpdateAppParams = data.into_inner().try_into()?;
    let _ = controller.update_app(params).await?;
    Ok(())
}

#[tracing::instrument(name = "read_app", skip(data, app_controller, view_controller))]
pub(crate) async fn read_app(
    data: Data<QueryAppRequest>,
    app_controller: Unit<Arc<AppController>>,
    view_controller: Unit<Arc<ViewController>>,
) -> DataResult<App, WorkspaceError> {
    let params: QueryAppParams = data.into_inner().try_into()?;
    let mut app = app_controller.read_app(&params.app_id, params.is_trash).await?;

    // The View's belonging is the view indexed by the belong_to_id for now
    if params.read_belongings {
        let views = view_controller.read_views_belong_to(&params.app_id).await?;
        app.belongings = RepeatedView { items: views };
    }

    data_result(app)
}
