use crate::{
    entities::{
        app::{App, CreateAppParams, CreateAppRequest, QueryAppParams, QueryAppRequest},
        view::RepeatedView,
    },
    errors::WorkspaceError,
    services::AppController,
};
use flowy_dispatch::prelude::{response_ok, Data, ModuleData, ResponseResult};
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "create_app", skip(data, controller))]
pub async fn create_app(
    data: Data<CreateAppRequest>,
    controller: ModuleData<Arc<AppController>>,
) -> ResponseResult<App, WorkspaceError> {
    let params: CreateAppParams = data.into_inner().try_into()?;
    let detail = controller.save_app(params)?;
    response_ok(detail)
}

#[tracing::instrument(name = "get_app", skip(data, controller))]
pub async fn get_app(
    data: Data<QueryAppRequest>,
    controller: ModuleData<Arc<AppController>>,
) -> ResponseResult<App, WorkspaceError> {
    let params: QueryAppParams = data.into_inner().try_into()?;
    let mut app = controller.get_app(&params.app_id).await?;
    if params.read_views {
        let views = controller.get_views(&params.app_id).await?;
        app.views = RepeatedView { items: views };
    }

    response_ok(app)
}
