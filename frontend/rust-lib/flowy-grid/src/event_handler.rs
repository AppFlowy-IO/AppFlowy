use crate::entities::*;
use crate::manager::GridManager;
use crate::services::cell::AnyCellData;
use crate::services::field::{
    default_type_option_builder_from_type, select_option_operation, type_option_builder_from_json_str,
    DateChangesetParams, DateChangesetPayloadPB, SelectOptionCellChangeset, SelectOptionCellChangesetParams,
    SelectOptionCellChangesetPayloadPB, SelectOptionCellDataPB, SelectOptionChangeset, SelectOptionChangesetPayloadPB,
    SelectOptionPB,
};
use crate::services::row::make_row_from_row_rev;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::FieldRevision;
use flowy_sync::entities::grid::{FieldChangesetParams, GridSettingChangesetParams};
use lib_dispatch::prelude::{data_result, AppData, Data, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_grid_handler(
    data: Data<GridIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<GridPB, FlowyError> {
    let grid_id: GridIdPB = data.into_inner();
    let editor = manager.open_grid(grid_id).await?;
    let grid = editor.get_grid_data().await?;
    data_result(grid)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_grid_setting_handler(
    data: Data<GridIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<GridSettingPB, FlowyError> {
    let grid_id: GridIdPB = data.into_inner();
    let editor = manager.open_grid(grid_id).await?;
    let grid_setting = editor.get_grid_setting().await?;
    data_result(grid_setting)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_grid_setting_handler(
    data: Data<GridSettingChangesetPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: GridSettingChangesetParams = data.into_inner().try_into()?;
    let editor = manager.open_grid(&params.grid_id).await?;
    let _ = editor.update_grid_setting(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_grid_blocks_handler(
    data: Data<QueryBlocksPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedBlockPB, FlowyError> {
    let params: QueryGridBlocksParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let repeated_grid_block = editor.get_blocks(Some(params.block_ids)).await?;
    data_result(repeated_grid_block)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
    data: Data<QueryFieldPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedFieldPB, FlowyError> {
    let params: QueryFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let field_orders = params
        .field_ids
        .items
        .into_iter()
        .map(|field_order| field_order.field_id)
        .collect();
    let field_revs = editor.get_field_revs(Some(field_orders)).await?;
    let repeated_field: RepeatedFieldPB = field_revs.into_iter().map(FieldPB::from).collect::<Vec<_>>().into();
    data_result(repeated_field)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_handler(
    data: Data<FieldChangesetPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: FieldChangesetParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&changeset.grid_id)?;
    let _ = editor.update_field(changeset).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn insert_field_handler(
    data: Data<InsertFieldPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: InsertFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.insert_field(params).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_type_option_handler(
    data: Data<UpdateFieldTypeOptionPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: UpdateFieldTypeOptionParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor
        .update_field_type_option(&params.grid_id, &params.field_id, params.type_option_data)
        .await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_field_handler(
    data: Data<DeleteFieldPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.delete_field(&params.field_id).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn switch_to_field_handler(
    data: Data<EditFieldPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<FieldTypeOptionDataPB, FlowyError> {
    let params: EditFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    editor
        .switch_to_field_type(&params.field_id, &params.field_type)
        .await?;

    // Get the FieldMeta with field_id, if it doesn't exist, we create the default FieldMeta from the FieldType.
    let field_rev = editor
        .get_field_rev(&params.field_id)
        .await
        .unwrap_or(Arc::new(editor.next_field_rev(&params.field_type).await?));

    let type_option_data = get_type_option_data(&field_rev, &params.field_type).await?;
    let data = FieldTypeOptionDataPB {
        grid_id: params.grid_id,
        field: field_rev.into(),
        type_option_data,
    };

    data_result(data)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
    data: Data<DuplicateFieldPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.duplicate_field(&params.field_id).await?;
    Ok(())
}

/// Return the FieldTypeOptionData if the Field exists otherwise return record not found error.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_field_type_option_data_handler(
    data: Data<FieldTypeOptionIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<FieldTypeOptionDataPB, FlowyError> {
    let params: FieldTypeOptionIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_field_rev(&params.field_id).await {
        None => Err(FlowyError::record_not_found()),
        Some(field_rev) => {
            let field_type = field_rev.field_type_rev.into();
            let type_option_data = get_type_option_data(&field_rev, &field_type).await?;
            let data = FieldTypeOptionDataPB {
                grid_id: params.grid_id,
                field: field_rev.into(),
                type_option_data,
            };
            data_result(data)
        }
    }
}

/// Create FieldMeta and save it. Return the FieldTypeOptionData.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn create_field_type_option_data_handler(
    data: Data<CreateFieldPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<FieldTypeOptionDataPB, FlowyError> {
    let params: CreateFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let field_rev = editor.create_next_field_rev(&params.field_type).await?;
    let field_type: FieldType = field_rev.field_type_rev.into();
    let type_option_data = get_type_option_data(&field_rev, &field_type).await?;

    data_result(FieldTypeOptionDataPB {
        grid_id: params.grid_id,
        field: field_rev.into(),
        type_option_data,
    })
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn move_item_handler(
    data: Data<MoveItemPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: MoveItemParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.move_item(params).await?;
    Ok(())
}

/// The FieldMeta contains multiple data, each of them belongs to a specific FieldType.
async fn get_type_option_data(field_rev: &FieldRevision, field_type: &FieldType) -> FlowyResult<Vec<u8>> {
    let s = field_rev
        .get_type_option_str(field_type)
        .unwrap_or_else(|| default_type_option_builder_from_type(field_type).entry().json_str());
    let field_type: FieldType = field_rev.field_type_rev.into();
    let builder = type_option_builder_from_json_str(&s, &field_type);
    let type_option_data = builder.entry().protobuf_bytes().to_vec();

    Ok(type_option_data)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_row_handler(
    data: Data<RowIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<OptionalRowPB, FlowyError> {
    let params: RowIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let row = editor
        .get_row_rev(&params.row_id)
        .await?
        .and_then(make_row_from_row_rev);

    data_result(OptionalRowPB { row })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_row_handler(
    data: Data<RowIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: RowIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.delete_row(&params.row_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_row_handler(
    data: Data<RowIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: RowIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    let _ = editor.duplicate_row(&params.row_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
    data: Data<CreateRowPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: CreateRowParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(params.grid_id.as_ref())?;
    let _ = editor.create_row(params.start_row_id).await?;
    Ok(())
}

// #[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_cell_handler(
    data: Data<GridCellIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<GridCellPB, FlowyError> {
    let params: GridCellIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_cell(&params).await {
        None => data_result(GridCellPB::empty(&params.field_id)),
        Some(cell) => data_result(cell),
    }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_cell_handler(
    data: Data<CellChangesetPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: CellChangesetPB = data.into_inner();
    let editor = manager.get_grid_editor(&changeset.grid_id)?;
    let _ = editor.update_cell(changeset).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn new_select_option_handler(
    data: Data<CreateSelectOptionPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<SelectOptionPB, FlowyError> {
    let params: CreateSelectOptionParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_field_rev(&params.field_id).await {
        None => Err(ErrorCode::InvalidData.into()),
        Some(field_rev) => {
            let type_option = select_option_operation(&field_rev)?;
            let select_option = type_option.create_option(&params.option_name);
            data_result(select_option)
        }
    }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_handler(
    data: Data<SelectOptionChangesetPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: SelectOptionChangeset = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&changeset.cell_identifier.grid_id)?;

    if let Some(mut field_rev) = editor.get_field_rev(&changeset.cell_identifier.field_id).await {
        let mut_field_rev = Arc::make_mut(&mut field_rev);
        let mut type_option = select_option_operation(mut_field_rev)?;
        let mut cell_content_changeset = None;

        if let Some(option) = changeset.insert_option {
            cell_content_changeset = Some(SelectOptionCellChangeset::from_insert(&option.id).to_str());
            type_option.insert_option(option);
        }

        if let Some(option) = changeset.update_option {
            type_option.insert_option(option);
        }

        if let Some(option) = changeset.delete_option {
            cell_content_changeset = Some(SelectOptionCellChangeset::from_delete(&option.id).to_str());
            type_option.delete_option(option);
        }

        mut_field_rev.insert_type_option_entry(&*type_option);
        let _ = editor.replace_field(field_rev).await?;

        let changeset = CellChangesetPB {
            grid_id: changeset.cell_identifier.grid_id,
            row_id: changeset.cell_identifier.row_id,
            field_id: changeset.cell_identifier.field_id,
            content: cell_content_changeset,
        };
        let _ = editor.update_cell(changeset).await?;
    }
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_select_option_handler(
    data: Data<GridCellIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<SelectOptionCellDataPB, FlowyError> {
    let params: GridCellIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id)?;
    match editor.get_field_rev(&params.field_id).await {
        None => {
            tracing::error!("Can't find the select option field with id: {}", params.field_id);
            data_result(SelectOptionCellDataPB::default())
        }
        Some(field_rev) => {
            //
            let cell_rev = editor.get_cell_rev(&params.row_id, &params.field_id).await?;
            let type_option = select_option_operation(&field_rev)?;
            let any_cell_data: AnyCellData = match cell_rev {
                None => AnyCellData {
                    data: "".to_string(),
                    field_type: field_rev.field_type_rev.into(),
                },
                Some(cell_rev) => cell_rev.try_into()?,
            };
            let option_context = type_option.selected_select_option(any_cell_data.into());
            data_result(option_context)
        }
    }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_cell_handler(
    data: Data<SelectOptionCellChangesetPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.cell_identifier.grid_id)?;
    let _ = editor.update_cell(params.into()).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_date_cell_handler(
    data: Data<DateChangesetPayloadPB>,
    manager: AppData<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: DateChangesetParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.cell_identifier.grid_id)?;
    let _ = editor.update_cell(params.into()).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_groups_handler(
    data: Data<GridIdPB>,
    manager: AppData<Arc<GridManager>>,
) -> DataResult<RepeatedGridGroupPB, FlowyError> {
    let params: GridIdPB = data.into_inner();
    let editor = manager.get_grid_editor(&params.value)?;
    let group = editor.load_groups().await?;
    data_result(group)
}
