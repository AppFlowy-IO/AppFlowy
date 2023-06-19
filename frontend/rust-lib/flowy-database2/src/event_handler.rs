use std::sync::Arc;

use collab_database::database::gen_row_id;
use collab_database::rows::RowId;

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use lib_infra::util::timestamp;

use crate::entities::*;
use crate::manager::DatabaseManager2;
use crate::services::cell::CellBuilder;
use crate::services::field::checklist_type_option::ChecklistCellChangeset;
use crate::services::field::{
  type_option_data_from_pb_or_default, DateCellChangeset, SelectOptionCellChangeset,
};
use crate::services::group::{GroupChangeset, GroupSettingChangeset};
use crate::services::share::csv::CSVFormat;

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_database_data_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<DatabasePB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database_with_view_id(view_id.as_ref()).await?;
  let data = database_editor.get_database_data(view_id.as_ref()).await?;
  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_database_id_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<DatabaseIdPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_id = manager
    .get_database_id_with_view_id(view_id.as_ref())
    .await?;
  data_result_ok(DatabaseIdPB { value: database_id })
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_database_setting_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<DatabaseViewSettingPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database_with_view_id(view_id.as_ref()).await?;
  let data = database_editor
    .get_database_view_setting(view_id.as_ref())
    .await?;
  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_database_setting_handler(
  data: AFPluginData<DatabaseSettingChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: DatabaseSettingChangesetParams = data.into_inner().try_into()?;
  let editor = manager.get_database_with_view_id(&params.view_id).await?;

  if let Some(update_filter) = params.insert_filter {
    editor.create_or_update_filter(update_filter).await?;
  }

  if let Some(delete_filter) = params.delete_filter {
    editor.delete_filter(delete_filter).await?;
  }

  if let Some(update_sort) = params.alert_sort {
    let _ = editor.create_or_update_sort(update_sort).await?;
  }
  if let Some(delete_sort) = params.delete_sort {
    editor.delete_sort(delete_sort).await?;
  }

  if let Some(layout_type) = params.layout_type {
    editor
      .update_view_layout(&params.view_id, layout_type)
      .await?;
  }
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_filters_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedFilterPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database_with_view_id(view_id.as_ref()).await?;
  let filters = database_editor.get_all_filters(view_id.as_ref()).await;
  data_result_ok(filters)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedSortPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database_with_view_id(view_id.as_ref()).await?;
  let sorts = database_editor.get_all_sorts(view_id.as_ref()).await;
  data_result_ok(sorts)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database_with_view_id(view_id.as_ref()).await?;
  database_editor.delete_all_sorts(view_id.as_ref()).await;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
  data: AFPluginData<GetFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedFieldPB, FlowyError> {
  let params: GetFieldParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let fields = database_editor
    .get_fields(&params.view_id, params.field_ids)
    .into_iter()
    .map(FieldPB::from)
    .collect::<Vec<FieldPB>>()
    .into();
  data_result_ok(fields)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_primary_field_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<FieldPB, FlowyError> {
  let view_id = data.into_inner().value;
  let database_editor = manager.get_database_with_view_id(&view_id).await?;
  let mut fields = database_editor
    .get_fields(&view_id, None)
    .into_iter()
    .filter(|field| field.is_primary)
    .map(FieldPB::from)
    .collect::<Vec<FieldPB>>();

  if fields.is_empty() {
    // The primary field should not be empty. Because it is created when the database is created.
    // If it is empty, it must be a bug.
    Err(FlowyError::record_not_found())
  } else {
    if fields.len() > 1 {
      // The primary field should not be more than one. If it is more than one,
      // it must be a bug.
      tracing::error!("The primary field is more than one");
    }
    data_result_ok(fields.remove(0))
  }
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_handler(
  data: AFPluginData<FieldChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: FieldChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor.update_field(params).await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_type_option_handler(
  data: AFPluginData<TypeOptionChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: TypeOptionChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  if let Some(old_field) = database_editor.get_field(&params.field_id) {
    let field_type = FieldType::from(old_field.field_type);
    let type_option_data =
      type_option_data_from_pb_or_default(params.type_option_data, &field_type);
    database_editor
      .update_field_type_option(
        &params.view_id,
        &params.field_id,
        type_option_data,
        old_field,
      )
      .await?;
  }
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_field_handler(
  data: AFPluginData<DeleteFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: FieldIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor.delete_field(&params.field_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn switch_to_field_handler(
  data: AFPluginData<UpdateFieldTypePayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: EditFieldParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let old_field = database_editor.get_field(&params.field_id);
  database_editor
    .switch_to_field_type(&params.field_id, &params.field_type)
    .await?;

  if let Some(new_type_option) = database_editor
    .get_field(&params.field_id)
    .map(|field| field.get_any_type_option(field.field_type))
  {
    match (old_field, new_type_option) {
      (Some(old_field), Some(new_type_option)) => {
        database_editor
          .update_field_type_option(
            &params.view_id,
            &params.field_id,
            new_type_option,
            old_field,
          )
          .await?;
      },
      _ => {
        tracing::warn!("Old field and the new type option should not be empty");
      },
    }
  }
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
  data: AFPluginData<DuplicateFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: FieldIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .duplicate_field(&params.view_id, &params.field_id)
    .await?;
  Ok(())
}

/// Return the FieldTypeOptionData if the Field exists otherwise return record not found error.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_field_type_option_data_handler(
  data: AFPluginData<TypeOptionPathPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<TypeOptionPB, FlowyError> {
  let params: TypeOptionPathParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  if let Some((field, data)) = database_editor
    .get_field_type_option_data(&params.field_id)
    .await
  {
    let data = TypeOptionPB {
      view_id: params.view_id,
      field: FieldPB::from(field),
      type_option_data: data.to_vec(),
    };
    data_result_ok(data)
  } else {
    Err(FlowyError::record_not_found())
  }
}

/// Create TypeOptionPB and save it. Return the FieldTypeOptionData.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn create_field_type_option_data_handler(
  data: AFPluginData<CreateFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<TypeOptionPB, FlowyError> {
  let params: CreateFieldParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let (field, data) = database_editor
    .create_field_with_type_option(&params.view_id, &params.field_type, params.type_option_data)
    .await;

  let data = TypeOptionPB {
    view_id: params.view_id,
    field: FieldPB::from(field),
    type_option_data: data.to_vec(),
  };
  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn move_field_handler(
  data: AFPluginData<MoveFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: MoveFieldParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .move_field(
      &params.view_id,
      &params.field_id,
      params.from_index,
      params.to_index,
    )
    .await?;
  Ok(())
}

// #[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<OptionalRowPB, FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let row = database_editor
    .get_row(&params.view_id, &params.row_id)
    .map(RowPB::from);
  data_result_ok(OptionalRowPB { row })
}

pub(crate) async fn get_row_meta_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RowMetaPB, FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  match database_editor.get_row_meta(&params.view_id, &params.row_id) {
    None => Err(FlowyError::record_not_found()),
    Some(row) => data_result_ok(row),
  }
}

pub(crate) async fn update_row_meta_handler(
  data: AFPluginData<UpdateRowMetaChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: UpdateRowMetaParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let row_id = RowId::from(params.id.clone());
  database_editor.update_row_meta(&row_id, params).await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor.delete_row(&params.row_id).await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .duplicate_row(&params.view_id, params.group_id, &params.row_id)
    .await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_row_handler(
  data: AFPluginData<MoveRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: MoveRowParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .move_row(&params.view_id, params.from_row_id, params.to_row_id)
    .await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
  data: AFPluginData<CreateRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RowMetaPB, FlowyError> {
  let params: CreateRowParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let fields = database_editor.get_fields(&params.view_id, None);
  let cells =
    CellBuilder::with_cells(params.cell_data_by_field_id.unwrap_or_default(), &fields).build();
  let view_id = params.view_id;
  let group_id = params.group_id;
  let params = collab_database::rows::CreateRowParams {
    id: gen_row_id(),
    cells,
    height: 60,
    visibility: true,
    prev_row_id: params.start_row_id,
    timestamp: timestamp(),
  };
  match database_editor
    .create_row(&view_id, group_id, params)
    .await?
  {
    None => Err(FlowyError::internal().context("Create row fail")),
    Some(row) => data_result_ok(RowMetaPB::from(row.meta)),
  }
}

// #[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_cell_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<CellPB, FlowyError> {
  let params: CellIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let cell = database_editor
    .get_cell_pb(&params.field_id, &params.row_id)
    .await
    .unwrap_or_else(|| CellPB::empty(&params.field_id, params.row_id.into_inner()));
  data_result_ok(cell)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_cell_handler(
  data: AFPluginData<CellChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: CellChangesetPB = data.into_inner();
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .update_cell_with_changeset(
      &params.view_id,
      RowId::from(params.row_id),
      &params.field_id,
      params.cell_changeset.clone(),
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn new_select_option_handler(
  data: AFPluginData<CreateSelectOptionPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<SelectOptionPB, FlowyError> {
  let params: CreateSelectOptionParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let result = database_editor
    .create_select_option(&params.field_id, params.option_name)
    .await;
  match result {
    None => {
      Err(FlowyError::record_not_found().context("Create select option fail. Can't find the field"))
    },
    Some(pb) => data_result_ok(pb),
  }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn insert_or_update_select_option_handler(
  data: AFPluginData<RepeatedSelectOptionPayload>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params = data.into_inner();
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .insert_select_options(
      &params.view_id,
      &params.field_id,
      RowId::from(params.row_id),
      params.items,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn delete_select_option_handler(
  data: AFPluginData<RepeatedSelectOptionPayload>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params = data.into_inner();
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .delete_select_options(
      &params.view_id,
      &params.field_id,
      RowId::from(params.row_id),
      params.items,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_select_option_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<SelectOptionCellDataPB, FlowyError> {
  let params: CellIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let options = database_editor
    .get_select_options(params.row_id, &params.field_id)
    .await;
  data_result_ok(options)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_cell_handler(
  data: AFPluginData<SelectOptionCellChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_with_view_id(&params.cell_identifier.view_id)
    .await?;
  let changeset = SelectOptionCellChangeset {
    insert_option_ids: params.insert_option_ids,
    delete_option_ids: params.delete_option_ids,
  };
  database_editor
    .update_cell_with_changeset(
      &params.cell_identifier.view_id,
      params.cell_identifier.row_id,
      &params.cell_identifier.field_id,
      changeset,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_checklist_cell_data_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<ChecklistCellDataPB, FlowyError> {
  let params: CellIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let data = database_editor
    .get_checklist_option(params.row_id, &params.field_id)
    .await;
  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_checklist_cell_handler(
  data: AFPluginData<ChecklistCellDataChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: ChecklistCellDataChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let changeset = ChecklistCellChangeset {
    insert_options: params.insert_options,
    selected_option_ids: params.selected_option_ids,
    delete_option_ids: params.delete_option_ids,
    update_options: params.update_options,
  };
  database_editor
    .set_checklist_options(&params.view_id, params.row_id, &params.field_id, changeset)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_date_cell_handler(
  data: AFPluginData<DateChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let data = data.into_inner();
  let cell_id: CellIdParams = data.cell_id.try_into()?;
  let cell_changeset = DateCellChangeset {
    date: data.date,
    time: data.time,
    include_time: data.include_time,
  };
  let database_editor = manager.get_database_with_view_id(&cell_id.view_id).await?;
  database_editor
    .update_cell_with_changeset(
      &cell_id.view_id,
      cell_id.row_id,
      &cell_id.field_id,
      cell_changeset,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_groups_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedGroupPB, FlowyError> {
  let params: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database_with_view_id(params.as_ref()).await?;
  let groups = database_editor.load_groups(params.as_ref()).await?;
  data_result_ok(groups)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_group_handler(
  data: AFPluginData<DatabaseGroupIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<GroupPB, FlowyError> {
  let params: DatabaseGroupIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let group = database_editor
    .get_group(&params.view_id, &params.group_id)
    .await?;
  data_result_ok(group)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn set_group_by_field_handler(
  data: AFPluginData<GroupByFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: GroupByFieldParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .set_group_by_field(&params.view_id, &params.field_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_group_handler(
  data: AFPluginData<UpdateGroupPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: UpdateGroupParams = data.into_inner().try_into()?;
  let view_id = params.view_id.clone();
  let database_editor = manager.get_database_with_view_id(&view_id).await?;
  let group_setting_changeset = GroupSettingChangeset {
    update_groups: vec![GroupChangeset::from(params)],
  };
  database_editor
    .update_group_setting(&view_id, group_setting_changeset)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_handler(
  data: AFPluginData<MoveGroupPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: MoveGroupParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .move_group(&params.view_id, &params.from_group_id, &params.to_group_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_row_handler(
  data: AFPluginData<MoveGroupRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: MoveGroupRowParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  database_editor
    .move_group_row(
      &params.view_id,
      &params.to_group_id,
      params.from_row_id,
      params.to_row_id,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn get_databases_handler(
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedDatabaseDescriptionPB, FlowyError> {
  let data = manager.get_all_databases_description().await;
  data_result_ok(data)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn set_layout_setting_handler(
  data: AFPluginData<LayoutSettingChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: LayoutSettingChangeset = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let layout_params = LayoutSettingParams {
    layout_type: params.layout_type,
    calendar: params.calendar,
  };
  database_editor
    .set_layout_setting(&params.view_id, layout_params)
    .await;
  Ok(())
}

pub(crate) async fn get_layout_setting_handler(
  data: AFPluginData<DatabaseLayoutMetaPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<DatabaseLayoutSettingPB, FlowyError> {
  let params: DatabaseLayoutMeta = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let layout_setting_pb = database_editor
    .get_layout_setting(&params.view_id, params.layout)
    .await
    .map(DatabaseLayoutSettingPB::from)
    .unwrap_or_default();
  data_result_ok(layout_setting_pb)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_calendar_events_handler(
  data: AFPluginData<CalendarEventRequestPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedCalendarEventPB, FlowyError> {
  let params: CalendarEventRequestParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let events = database_editor
    .get_all_calendar_events(&params.view_id)
    .await;
  data_result_ok(RepeatedCalendarEventPB { items: events })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_no_date_calendar_events_handler(
  data: AFPluginData<CalendarEventRequestPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedNoDateCalendarEventPB, FlowyError> {
  let params: CalendarEventRequestParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let _events = database_editor
    .get_all_no_date_calendar_events(&params.view_id)
    .await;
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_calendar_event_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<CalendarEventPB, FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_with_view_id(&params.view_id).await?;
  let event = database_editor
    .get_calendar_event(&params.view_id, params.row_id)
    .await;
  match event {
    None => Err(FlowyError::record_not_found()),
    Some(event) => data_result_ok(event),
  }
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_calendar_event_handler(
  data: AFPluginData<MoveCalendarEventPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let data = data.into_inner();
  let cell_id: CellIdParams = data.cell_path.try_into()?;
  let cell_changeset = DateCellChangeset {
    date: Some(data.timestamp.to_string()),
    ..Default::default()
  };
  let database_editor = manager.get_database_with_view_id(&cell_id.view_id).await?;
  database_editor
    .update_cell_with_changeset(
      &cell_id.view_id,
      cell_id.row_id,
      &cell_id.field_id,
      cell_changeset,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn create_database_view(
  _data: AFPluginData<CreateDatabaseViewPayloadPB>,
  _manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  // let data: CreateDatabaseViewParams = data.into_inner().try_into()?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn export_csv_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<DatabaseExportDataPB, FlowyError> {
  let view_id = data.into_inner().value;
  let database = manager.get_database_with_view_id(&view_id).await?;
  let data = database.export_csv(CSVFormat::Original).await?;
  data_result_ok(DatabaseExportDataPB {
    export_type: DatabaseExportDataType::CSV,
    data,
  })
}
