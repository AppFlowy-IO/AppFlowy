use crate::entities::*;
use crate::manager::GridManager;
use crate::services::cell::{FromCellString, ToCellChangesetString, TypeCellData};
use crate::services::field::{
    default_type_option_builder_from_type, select_type_option_from_field_rev, type_option_builder_from_json_str,
    DateCellChangeset, DateChangesetPB, SelectOptionCellChangeset, SelectOptionCellChangesetPB,
    SelectOptionCellChangesetParams, SelectOptionCellDataPB, SelectOptionChangeset, SelectOptionChangesetPB,
    SelectOptionIds, SelectOptionPB,
};
use crate::services::row::make_row_from_row_rev;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use grid_rev_model::FieldRevision;
use lib_dispatch::prelude::{data_result, AFPluginData, AFPluginState, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_grid_handler(
    data: AFPluginData<GridIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<GridPB, FlowyError> {
    let grid_id: GridIdPB = data.into_inner();
    let editor = manager.open_grid(grid_id.as_ref()).await?;
    let grid = editor.get_grid(grid_id.as_ref()).await?;
    data_result(grid)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_grid_setting_handler(
    data: AFPluginData<GridIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<GridSettingPB, FlowyError> {
    let grid_id: GridIdPB = data.into_inner();
    let editor = manager.open_grid(grid_id).await?;
    let grid_setting = editor.get_setting().await?;
    data_result(grid_setting)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_grid_setting_handler(
    data: AFPluginData<GridSettingChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: GridSettingChangesetParams = data.into_inner().try_into()?;

    let editor = manager.get_grid_editor(&params.grid_id).await?;
    if let Some(insert_params) = params.insert_group {
        let _ = editor.insert_group(insert_params).await?;
    }

    if let Some(delete_params) = params.delete_group {
        let _ = editor.delete_group(delete_params).await?;
    }

    if let Some(alter_filter) = params.insert_filter {
        let _ = editor.create_or_update_filter(alter_filter).await?;
    }

    if let Some(delete_filter) = params.delete_filter {
        let _ = editor.delete_filter(delete_filter).await?;
    }

    if let Some(alter_sort) = params.alert_sort {
        let _ = editor.create_or_update_sort(alter_sort).await?;
    }
    if let Some(delete_sort) = params.delete_sort {
        let _ = editor.delete_sort(delete_sort).await?;
    }
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_filters_handler(
    data: AFPluginData<GridIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<RepeatedFilterPB, FlowyError> {
    let grid_id: GridIdPB = data.into_inner();
    let editor = manager.open_grid(grid_id).await?;
    let filters = RepeatedFilterPB {
        items: editor.get_all_filters().await?,
    };
    data_result(filters)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_sorts_handler(
    data: AFPluginData<GridIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<RepeatedSortPB, FlowyError> {
    let grid_id: GridIdPB = data.into_inner();
    let editor = manager.open_grid(grid_id.as_ref()).await?;
    let sorts = RepeatedSortPB {
        items: editor.get_all_sorts(grid_id.as_ref()).await?,
    };
    data_result(sorts)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_all_sorts_handler(
    data: AFPluginData<GridIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let grid_id: GridIdPB = data.into_inner();
    let editor = manager.open_grid(grid_id.as_ref()).await?;
    let _ = editor.delete_all_sorts(grid_id.as_ref()).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
    data: AFPluginData<GetFieldPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<RepeatedFieldPB, FlowyError> {
    let params: GetFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let field_revs = editor.get_field_revs(params.field_ids).await?;
    let repeated_field: RepeatedFieldPB = field_revs.into_iter().map(FieldPB::from).collect::<Vec<_>>().into();
    data_result(repeated_field)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_handler(
    data: AFPluginData<FieldChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: FieldChangesetParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&changeset.grid_id).await?;
    let _ = editor.update_field(changeset).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_type_option_handler(
    data: AFPluginData<TypeOptionChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: TypeOptionChangesetParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let old_field_rev = editor.get_field_rev(&params.field_id).await;
    let _ = editor
        .update_field_type_option(
            &params.grid_id,
            &params.field_id,
            params.type_option_data,
            old_field_rev,
        )
        .await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_field_handler(
    data: AFPluginData<DeleteFieldPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let _ = editor.delete_field(&params.field_id).await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn switch_to_field_handler(
    data: AFPluginData<EditFieldChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: EditFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let old_field_rev = editor.get_field_rev(&params.field_id).await;
    editor
        .switch_to_field_type(&params.field_id, &params.field_type)
        .await?;

    // Get the field_rev with field_id, if it doesn't exist, we create the default FieldRevision from the FieldType.
    let new_field_rev = editor
        .get_field_rev(&params.field_id)
        .await
        .unwrap_or(Arc::new(editor.next_field_rev(&params.field_type).await?));

    // Update the type-option data after the field type has been changed
    let type_option_data = get_type_option_data(&new_field_rev, &params.field_type).await?;
    let _ = editor
        .update_field_type_option(&params.grid_id, &new_field_rev.id, type_option_data, old_field_rev)
        .await?;

    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
    data: AFPluginData<DuplicateFieldPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: FieldIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let _ = editor.duplicate_field(&params.field_id).await?;
    Ok(())
}

/// Return the FieldTypeOptionData if the Field exists otherwise return record not found error.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_field_type_option_data_handler(
    data: AFPluginData<TypeOptionPathPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<TypeOptionPB, FlowyError> {
    let params: TypeOptionPathParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    match editor.get_field_rev(&params.field_id).await {
        None => Err(FlowyError::record_not_found()),
        Some(field_rev) => {
            let field_type = field_rev.ty.into();
            let type_option_data = get_type_option_data(&field_rev, &field_type).await?;
            let data = TypeOptionPB {
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
    data: AFPluginData<CreateFieldPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<TypeOptionPB, FlowyError> {
    let params: CreateFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let field_rev = editor
        .create_new_field_rev_with_type_option(&params.field_type, params.type_option_data)
        .await?;
    let field_type: FieldType = field_rev.ty.into();
    let type_option_data = get_type_option_data(&field_rev, &field_type).await?;

    data_result(TypeOptionPB {
        grid_id: params.grid_id,
        field: field_rev.into(),
        type_option_data,
    })
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn move_field_handler(
    data: AFPluginData<MoveFieldPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: MoveFieldParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let _ = editor.move_field(params).await?;
    Ok(())
}

/// The [FieldRevision] contains multiple data, each of them belongs to a specific FieldType.
async fn get_type_option_data(field_rev: &FieldRevision, field_type: &FieldType) -> FlowyResult<Vec<u8>> {
    let s = field_rev.get_type_option_str(field_type).unwrap_or_else(|| {
        default_type_option_builder_from_type(field_type)
            .serializer()
            .json_str()
    });
    let field_type: FieldType = field_rev.ty.into();
    let builder = type_option_builder_from_json_str(&s, &field_type);
    let type_option_data = builder.serializer().protobuf_bytes().to_vec();

    Ok(type_option_data)
}

// #[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_row_handler(
    data: AFPluginData<RowIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<OptionalRowPB, FlowyError> {
    let params: RowIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let row = editor.get_row_rev(&params.row_id).await?.map(make_row_from_row_rev);

    data_result(OptionalRowPB { row })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_row_handler(
    data: AFPluginData<RowIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: RowIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let _ = editor.delete_row(&params.row_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_row_handler(
    data: AFPluginData<RowIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: RowIdParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    let _ = editor.duplicate_row(&params.row_id).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_row_handler(
    data: AFPluginData<MoveRowPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: MoveRowParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.view_id).await?;
    let _ = editor.move_row(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_table_row_handler(
    data: AFPluginData<CreateTableRowPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<RowPB, FlowyError> {
    let params: CreateRowParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(params.grid_id.as_ref()).await?;
    let row = editor.create_row(params).await?;
    data_result(row)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_cell_handler(
    data: AFPluginData<CellPathPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<CellPB, FlowyError> {
    let params: CellPathParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.view_id).await?;
    match editor.get_cell(&params).await {
        None => data_result(CellPB::empty(&params.field_id)),
        Some(cell) => data_result(cell),
    }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_cell_handler(
    data: AFPluginData<CellChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: CellChangesetPB = data.into_inner();
    let editor = manager.get_grid_editor(&changeset.grid_id).await?;
    let _ = editor
        .update_cell_with_changeset(&changeset.row_id, &changeset.field_id, changeset.type_cell_data)
        .await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn new_select_option_handler(
    data: AFPluginData<CreateSelectOptionPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<SelectOptionPB, FlowyError> {
    let params: CreateSelectOptionParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.grid_id).await?;
    match editor.get_field_rev(&params.field_id).await {
        None => Err(ErrorCode::InvalidData.into()),
        Some(field_rev) => {
            let type_option = select_type_option_from_field_rev(&field_rev)?;
            let select_option = type_option.create_option(&params.option_name);
            data_result(select_option)
        }
    }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_handler(
    data: AFPluginData<SelectOptionChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let changeset: SelectOptionChangeset = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&changeset.cell_path.view_id).await?;
    let field_id = changeset.cell_path.field_id.clone();
    let _ = editor
        .modify_field_rev(&field_id, |field_rev| {
            let mut type_option = select_type_option_from_field_rev(field_rev)?;
            let mut cell_changeset_str = None;
            let mut is_changed = None;

            for option in changeset.insert_options {
                cell_changeset_str =
                    Some(SelectOptionCellChangeset::from_insert_option_id(&option.id).to_cell_changeset_str());
                type_option.insert_option(option);
                is_changed = Some(());
            }

            for option in changeset.update_options {
                type_option.insert_option(option);
                is_changed = Some(());
            }

            for option in changeset.delete_options {
                cell_changeset_str =
                    Some(SelectOptionCellChangeset::from_delete_option_id(&option.id).to_cell_changeset_str());
                type_option.delete_option(option);
                is_changed = Some(());
            }

            if is_changed.is_some() {
                field_rev.insert_type_option(&*type_option);
            }

            if let Some(cell_changeset_str) = cell_changeset_str {
                let cloned_editor = editor.clone();
                tokio::spawn(async move {
                    match cloned_editor
                        .update_cell_with_changeset(
                            &changeset.cell_path.row_id,
                            &changeset.cell_path.field_id,
                            cell_changeset_str,
                        )
                        .await
                    {
                        Ok(_) => {}
                        Err(e) => tracing::error!("{}", e),
                    }
                });
            }
            Ok(is_changed)
        })
        .await?;

    Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_select_option_handler(
    data: AFPluginData<CellPathPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<SelectOptionCellDataPB, FlowyError> {
    let params: CellPathParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.view_id).await?;
    match editor.get_field_rev(&params.field_id).await {
        None => {
            tracing::error!("Can't find the select option field with id: {}", params.field_id);
            data_result(SelectOptionCellDataPB::default())
        }
        Some(field_rev) => {
            //
            let cell_rev = editor.get_cell_rev(&params.row_id, &params.field_id).await?;
            let type_option = select_type_option_from_field_rev(&field_rev)?;
            let type_cell_data: TypeCellData = match cell_rev {
                None => TypeCellData {
                    cell_str: "".to_string(),
                    field_type: field_rev.ty.into(),
                },
                Some(cell_rev) => cell_rev.try_into()?,
            };
            let ids = SelectOptionIds::from_cell_str(&type_cell_data.cell_str)?;
            let selected_options = type_option.get_selected_options(ids);
            data_result(selected_options)
        }
    }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_cell_handler(
    data: AFPluginData<SelectOptionCellChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(&params.cell_identifier.view_id).await?;
    let changeset = SelectOptionCellChangeset {
        insert_option_ids: params.insert_option_ids,
        delete_option_ids: params.delete_option_ids,
    };

    let _ = editor
        .update_cell_with_changeset(
            &params.cell_identifier.row_id,
            &params.cell_identifier.field_id,
            changeset,
        )
        .await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_date_cell_handler(
    data: AFPluginData<DateChangesetPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> Result<(), FlowyError> {
    let data = data.into_inner();
    let cell_path: CellPathParams = data.cell_path.try_into()?;
    let cell_changeset = DateCellChangeset {
        date: data.date,
        time: data.time,
        is_utc: data.is_utc,
    };

    let editor = manager.get_grid_editor(&cell_path.view_id).await?;
    let _ = editor
        .update_cell(cell_path.row_id, cell_path.field_id, cell_changeset)
        .await?;
    Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_groups_handler(
    data: AFPluginData<GridIdPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<RepeatedGroupPB, FlowyError> {
    let params: GridIdPB = data.into_inner();
    let editor = manager.get_grid_editor(&params.value).await?;
    let group = editor.load_groups().await?;
    data_result(group)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_board_card_handler(
    data: AFPluginData<CreateBoardCardPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> DataResult<RowPB, FlowyError> {
    let params: CreateRowParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(params.grid_id.as_ref()).await?;
    let row = editor.create_row(params).await?;
    data_result(row)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_handler(
    data: AFPluginData<MoveGroupPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> FlowyResult<()> {
    let params: MoveGroupParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(params.view_id.as_ref()).await?;
    let _ = editor.move_group(params).await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_row_handler(
    data: AFPluginData<MoveGroupRowPayloadPB>,
    manager: AFPluginState<Arc<GridManager>>,
) -> FlowyResult<()> {
    let params: MoveGroupRowParams = data.into_inner().try_into()?;
    let editor = manager.get_grid_editor(params.view_id.as_ref()).await?;
    let _ = editor.move_group_row(params).await?;
    Ok(())
}
