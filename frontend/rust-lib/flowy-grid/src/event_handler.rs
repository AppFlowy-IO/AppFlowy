use crate::manager::GridManager;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{
    CreateGridPayload, Grid, GridId, RepeatedField, RepeatedFieldOrder, RepeatedRow, RepeatedRowOrder,
};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::sync::Arc;

#[tracing::instrument(skip(data, manager), err)]
pub(crate) async fn open_grid_handler(
    data: Data<GridId>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<Grid, FlowyError> {
    let grid_id: GridId = data.into_inner();
    let editor = manager.open_grid(grid_id).await?;
    let grid = editor.grid_data().await;
    data_result(grid)
}

#[tracing::instrument(skip(data, manager), err)]
pub(crate) async fn get_rows_handler(
    data: Data<RepeatedRowOrder>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedRow, FlowyError> {
    let row_orders: RepeatedRowOrder = data.into_inner();
    let repeated_row = manager.get_rows(row_orders).await;
    data_result(repeated_row)
}

#[tracing::instrument(skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
    data: Data<RepeatedFieldOrder>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedField, FlowyError> {
    let field_orders: RepeatedFieldOrder = data.into_inner();
    let repeated_field = manager.get_fields(field_orders).await;
    data_result(repeated_field)
}

#[tracing::instrument(skip(data, manager), err)]
pub(crate) async fn create_row_handler(
    data: Data<GridId>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let id: GridId = data.into_inner();
    let editor = manager.get_grid_editor(id.as_ref())?;
    let _ = editor.create_empty_row().await?;
    Ok(())
}
