use crate::{
    entities::app::{App, CreateAppParams, CreateAppRequest},
    errors::WorkspaceError,
    services::AppController,
};
use flowy_dispatch::prelude::{response_ok, Data, ModuleData, ResponseResult};
use std::{convert::TryInto, sync::Arc};

pub async fn create_app(
    data: Data<CreateAppRequest>,
    controller: ModuleData<Arc<AppController>>,
) -> ResponseResult<App, WorkspaceError> {
    let params: CreateAppParams = data.into_inner().try_into()?;
    let detail = controller.save_app(params)?;
    response_ok(detail)
}
