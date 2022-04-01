use crate::manager::GridManager;
use crate::services::field::{type_option_data_from_str, SelectOption};
use crate::services::grid_editor::ClientGridEditor;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::*;
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
    data: Data<FieldChangesetPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: FieldChangesetParams = data.into_inner().try_into()?;
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
pub(crate) async fn delete_field_handler(
    data: Data<FieldIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdentifierParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.delete_field(&params.field_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn switch_to_field_handler(
    data: Data<EditFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<EditFieldContext, FlowyError> {
    let params: EditFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let edit_context = editor.switch_to_field_type(&params.field_id, params.field_type).await?;
    data_result(edit_context)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
    data: Data<FieldIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdentifierParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.duplicate_field(&params.field_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data), err)]
pub(crate) async fn create_select_option_handler(
    data: Data<CreateSelectOptionPayload>,
) -> DataResult<SelectOption, FlowyError> {
    let params: CreateSelectOptionParams = data.into_inner().try_into()?;
    data_result(SelectOption::new(&params.option_name))
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_field_context_handler(
    data: Data<GetEditFieldContextPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<EditFieldContext, FlowyError> {
    let params = data.into_inner();
    let editor = manager.get_grid_editor(&params.grid_id)?;

    let mut field_meta = get_or_create_field_meta(&params, editor).await?;
    let type_option_data = type_option_data_from_str(&field_meta.type_option_json, &field_meta.field_type);
    let field: Field = field_meta.into();
    let edit_context = EditFieldContext {
        grid_id: params.grid_id,
        grid_field: field,
        type_option_data,
    };
    data_result(edit_context)
}

async fn get_or_create_field_meta(
    params: &GetEditFieldContextPayload,
    editor: Arc<ClientGridEditor>,
) -> FlowyResult<FieldMeta> {
    if params.field_id.is_some() {
        if let Some(field_meta) = editor.get_field(params.field_id.as_ref().unwrap()).await? {
            return Ok(field_meta);
        }
    }

    editor.default_field_meta(&params.field_type).await
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
