use crate::manager::GridManager;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{
    CellMetaChangeset, CreateRowPayload, Field, Grid, GridId, QueryFieldPayload, QueryGridBlocksPayload, RepeatedField,
    RepeatedGridBlock, Row,
};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_grid_data_handler(
    data: Data<GridId>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<Grid, FlowyError> {
    let grid_id: GridId = data.into_inner();
    let editor = manager.open_grid(grid_id).await?;
    let grid = editor.grid_data().await?;
    data_result(grid)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_grid_blocks_handler(
    data: Data<QueryGridBlocksPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedGridBlock, FlowyError> {
    let payload: QueryGridBlocksPayload = data.into_inner();
    let editor = manager.get_grid_editor(&payload.grid_id)?;
    let repeated_grid_block = editor.get_grid_blocks(Some(payload.blocks)).await?;
    data_result(repeated_grid_block)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
    data: Data<QueryFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedField, FlowyError> {
    let payload: QueryFieldPayload = data.into_inner();
    let editor = manager.get_grid_editor(&payload.grid_id)?;
    let field_metas = editor.get_field_metas(Some(payload.field_orders)).await?;
    let repeated_field: RepeatedField = field_metas.into_iter().map(Field::from).collect::<Vec<_>>().into();
    data_result(repeated_field)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
    data: Data<CreateRowPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let payload: CreateRowPayload = data.into_inner();
    let editor = manager.get_grid_editor(payload.grid_id.as_ref())?;
    let _ = editor.create_row(payload.upper_row_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_cell_handler(
    data: Data<CellMetaChangeset>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: CellMetaChangeset = data.into_inner();
    let editor = manager.get_grid_editor(&changeset.grid_id)?;
    let _ = editor.update_cell(changeset).await?;
    Ok(())
}
