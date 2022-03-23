use crate::manager::GridManager;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{
    CellMetaChangeset, CreateFieldPayload, CreateRowPayload, Field, FieldChangeset, Grid, GridId, QueryFieldPayload,
    QueryGridBlocksPayload, QueryRowPayload, RepeatedField, RepeatedGridBlock, Row,
};
use flowy_grid_data_model::parser::{
    CreateFieldParams, CreateRowParams, QueryFieldParams, QueryGridBlocksParams, QueryRowParams,
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
    let params: QueryGridBlocksParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let block_ids = params
        .block_orders
        .into_iter()
        .map(|block| block.block_id)
        .collect::<Vec<String>>();
    let repeated_grid_block = editor.get_blocks(Some(block_ids)).await?;
    data_result(repeated_grid_block)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
    data: Data<QueryFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedField, FlowyError> {
    let params: QueryFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let field_metas = editor.get_field_metas(Some(params.field_orders)).await?;
    let repeated_field: RepeatedField = field_metas.into_iter().map(Field::from).collect::<Vec<_>>().into();
    data_result(repeated_field)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn update_field_handler(
    data: Data<FieldChangeset>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: FieldChangeset = data.into_inner();
    let editor = manager.get_grid_editor(&changeset.grid_id)?;
    let _ = editor.update_field(changeset).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_field_handler(
    data: Data<CreateFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: CreateFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.create_field(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_row_handler(
    data: Data<QueryRowPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<Row, FlowyError> {
    let params: QueryRowParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_row(&params.block_id, &params.row_id).await? {
        None => Err(FlowyError::record_not_found().context("Can not find the row")),
        Some(row) => data_result(row),
    }
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
    data: Data<CreateRowPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: CreateRowParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(params.grid_id.as_ref())?;
    let _ = editor.create_row(params.start_row_id).await?;
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
