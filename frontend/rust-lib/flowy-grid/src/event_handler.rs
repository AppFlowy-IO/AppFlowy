use crate::manager::GridManager;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{Grid, GridId, QueryFieldPayload, QueryRowPayload, RepeatedField, RepeatedRow};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn open_grid_handler(
    data: Data<GridId>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<Grid, FlowyError> {
    let grid_id: GridId = data.into_inner();
    let editor = manager.open_grid(grid_id).await?;
    let grid = editor.grid_data().await;
    data_result(grid)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_rows_handler(
    data: Data<QueryRowPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedRow, FlowyError> {
    let payload: QueryRowPayload = data.into_inner();
    let editor = manager.get_grid_editor(&payload.grid_id)?;
    let repeated_row = editor.get_rows(payload.row_orders).await?;
    data_result(repeated_row)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
    data: Data<QueryFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedField, FlowyError> {
    let payload: QueryFieldPayload = data.into_inner();
    let editor = manager.get_grid_editor(&payload.grid_id)?;
    let repeated_field = editor.get_fields(payload.field_orders).await?;
    data_result(repeated_field)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
    data: Data<GridId>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let id: GridId = data.into_inner();
    let editor = manager.get_grid_editor(id.as_ref())?;
    let _ = editor.create_empty_row().await?;
    Ok(())
}
