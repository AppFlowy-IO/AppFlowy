use crate::{
    entities::view::{CreateViewParams, CreateViewRequest, View},
    errors::WorkspaceError,
    services::ViewController,
};
use flowy_dispatch::prelude::{response_ok, Data, ResponseResult, Unit};
use std::{convert::TryInto, sync::Arc};

pub async fn create_view(
    data: Data<CreateViewRequest>,
    controller: Unit<Arc<ViewController>>,
) -> ResponseResult<View, WorkspaceError> {
    let params: CreateViewParams = data.into_inner().try_into()?;
    let view = controller.create_view(params).await?;
    response_ok(view)
}
