use crate::controller::GridManager;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{CreateGridPayload, Grid, GridId};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::sync::Arc;

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn create_grid_handler(
    data: Data<CreateGridPayload>,
    controller: AppData<Arc<GridManager>>,
) -> DataResult<Grid, FlowyError> {
    todo!()
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn open_grid_handler(
    data: Data<GridId>,
    controller: AppData<Arc<GridManager>>,
) -> DataResult<Grid, FlowyError> {
    let params: GridId = data.into_inner();

    todo!()
}
