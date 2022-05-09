use crate::manager::GridManager;
use crate::services::entities::*;
use crate::services::field::type_options::*;
use crate::services::field::{default_type_option_builder_from_type, type_option_builder_from_json_str};
use crate::services::grid_editor::ClientGridEditor;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
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
    let field_orders = params.field_orders.items;
    let field_metas = editor.get_field_metas(Some(field_orders)).await?;
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
pub(crate) async fn insert_field_handler(
    data: Data<InsertFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: InsertFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.insert_field(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_field_handler(
    data: Data<FieldIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdentifier = data.into_inner().try_into()?;
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
    if params.field_id.is_none() {
        return Err(ErrorCode::FieldIdIsEmpty.into());
    }
    let field_id = params.field_id.unwrap();
    let editor = manager.get_grid_editor(&params.grid_id)?;
    editor.switch_to_field_type(&field_id, &params.field_type).await?;
    let field_meta = editor.get_field_meta(&field_id).await;
    let edit_context =
        make_edit_field_context(&params.grid_id, Some(field_id), params.field_type, editor, field_meta).await?;
    data_result(edit_context)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
    data: Data<FieldIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdentifier = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.duplicate_field(&params.field_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_field_context_handler(
    data: Data<EditFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<EditFieldContext, FlowyError> {
    let params: EditFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let edit_context =
        make_edit_field_context(&params.grid_id, params.field_id, params.field_type, editor, None).await?;

    data_result(edit_context)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_field_type_option_data_handler(
    data: Data<EditFieldPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<FieldTypeOptionData, FlowyError> {
    let params: EditFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let field_meta = get_or_create_field_meta(params.field_id, &params.field_type, editor).await?;
    let type_option_data = get_type_option_data(&field_meta, &field_meta.field_type).await?;

    data_result(FieldTypeOptionData {
        field_id: field_meta.id.clone(),
        type_option_data,
    })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_item_handler(
    data: Data<MoveItemPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: MoveItemParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.move_item(params).await?;
    Ok(())
}

async fn make_edit_field_context(
    grid_id: &str,
    field_id: Option<String>,
    field_type: FieldType,
    editor: Arc<ClientGridEditor>,
    field_meta: Option<FieldMeta>,
) -> FlowyResult<EditFieldContext> {
    let field_meta = field_meta.unwrap_or(get_or_create_field_meta(field_id, &field_type, editor).await?);
    let type_option_data = get_type_option_data(&field_meta, &field_type).await?;
    let field: Field = field_meta.into();
    Ok(EditFieldContext {
        grid_id: grid_id.to_string(),
        grid_field: field,
        type_option_data,
    })
}

async fn get_type_option_data(field_meta: &FieldMeta, field_type: &FieldType) -> FlowyResult<Vec<u8>> {
    let s = field_meta
        .get_type_option_str(&field_type)
        .unwrap_or_else(|| default_type_option_builder_from_type(&field_type).entry().json_str());
    let builder = type_option_builder_from_json_str(&s, &field_meta.field_type);
    let type_option_data = builder.entry().protobuf_bytes().to_vec();

    Ok(type_option_data)
}

async fn get_or_create_field_meta(
    field_id: Option<String>,
    field_type: &FieldType,
    editor: Arc<ClientGridEditor>,
) -> FlowyResult<FieldMeta> {
    match field_id {
        None => editor.create_next_field_meta(field_type).await,
        Some(field_id) => match editor.get_field_meta(&field_id).await {
            None => editor.create_next_field_meta(field_type).await,
            Some(field_meta) => Ok(field_meta),
        },
    }
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_row_handler(
    data: Data<RowIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<Row, FlowyError> {
    let params: RowIdentifier = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_row(&params.row_id).await? {
        None => Err(FlowyError::record_not_found().context("Can not find the row")),
        Some(row) => data_result(row),
    }
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_row_handler(
    data: Data<RowIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: RowIdentifier = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.delete_row(&params.row_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_row_handler(
    data: Data<RowIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: RowIdentifier = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.duplicate_row(&params.row_id).await?;
    Ok(())
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

// #[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_cell_handler(
    data: Data<CellIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<Cell, FlowyError> {
    let params: CellIdentifier = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_cell(&params).await {
        None => data_result(Cell::empty(&params.field_id)),
        Some(cell) => data_result(cell),
    }
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_cell_handler(
    data: Data<CellChangeset>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: CellChangeset = data.into_inner();
    let editor = manager.get_grid_editor(&changeset.grid_id)?;
    let _ = editor.update_cell(changeset).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn new_select_option_handler(
    data: Data<CreateSelectOptionPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<SelectOption, FlowyError> {
    let params: CreateSelectOptionParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_field_meta(&params.field_id).await {
        None => Err(ErrorCode::InvalidData.into()),
        Some(field_meta) => {
            let type_option = select_option_operation(&field_meta)?;
            let select_option = type_option.create_option(&params.option_name);
            data_result(select_option)
        }
    }
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_select_option_handler(
    data: Data<SelectOptionChangesetPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: SelectOptionChangeset = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&changeset.cell_identifier.grid_id)?;

    if let Some(mut field_meta) = editor.get_field_meta(&changeset.cell_identifier.field_id).await {
        let mut type_option = select_option_operation(&field_meta)?;
        let mut cell_data = None;

        if let Some(option) = changeset.insert_option {
            cell_data = Some(SelectOptionCellChangeset::from_insert(&option.id).cell_data());
            type_option.insert_option(option);
        }

        if let Some(option) = changeset.update_option {
            type_option.insert_option(option);
        }

        if let Some(option) = changeset.delete_option {
            cell_data = Some(SelectOptionCellChangeset::from_delete(&option.id).cell_data());
            type_option.delete_option(option);
        }

        field_meta.insert_type_option_entry(&*type_option);
        let _ = editor.replace_field(field_meta).await?;

        let changeset = CellChangeset {
            grid_id: changeset.cell_identifier.grid_id,
            row_id: changeset.cell_identifier.row_id,
            field_id: changeset.cell_identifier.field_id,
            data: cell_data,
        };
        let _ = editor.update_cell(changeset).await?;
    }
    Ok(())
}
//
// #[tracing::instrument(level = "debug", skip_all, err)]
// pub(crate) async fn update_date_option_handler(
//     data: Data<SelectOptionCellChangesetPayload>,
//     manager: AppData<Arc<GridManager>>,
// ) -> Result<(), FlowyError> {
//     let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;
//     let editor = manager.get_grid_editor(&params.grid_id)?;
//     let changeset: CellChangeset = params.into();
//     let _ = editor.update_cell(changeset).await?;
//     Ok(())
// }

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_select_option_handler(
    data: Data<CellIdentifierPayload>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<SelectOptionContext, FlowyError> {
    let params: CellIdentifier = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_field_meta(&params.field_id).await {
        None => {
            tracing::error!("Can't find the corresponding field with id: {}", params.field_id);
            data_result(SelectOptionContext::default())
        }
        Some(field_meta) => {
            let cell_meta = editor.get_cell_meta(&params.row_id, &params.field_id).await?;
            let type_option = select_option_operation(&field_meta)?;
            let option_context = type_option.option_context(&cell_meta);
            data_result(option_context)
        }
    }
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_cell_select_option_handler(
    data: Data<SelectOptionCellChangesetPayload>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let changeset: CellChangeset = params.into();
    let _ = editor.update_cell(changeset).await?;
    Ok(())
}
