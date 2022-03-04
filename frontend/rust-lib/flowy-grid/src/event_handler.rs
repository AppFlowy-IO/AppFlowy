use crate::manager::GridManager;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{
    CreateGridPayload, Grid, GridId, RepeatedField, RepeatedFieldOrder, RepeatedRow, RepeatedRowOrder,
};
use lib_dispatch::prelude::{AppData, Data, DataResult};
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
    let _params: GridId = data.into_inner();

    todo!()
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn get_rows_handler(
    data: Data<RepeatedRowOrder>,
    controller: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedRow, FlowyError> {
    let row_orders: RepeatedRowOrder = data.into_inner();

    todo!()
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn get_fields_handler(
    data: Data<RepeatedFieldOrder>,
    controller: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedField, FlowyError> {
    let field_orders: RepeatedFieldOrder = data.into_inner();

    todo!()
}

#[tracing::instrument(skip(data, controller), err)]
pub(crate) async fn create_row_handler(
    data: Data<GridId>,
    controller: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let id: GridId = data.into_inner();

    Ok(())
}
