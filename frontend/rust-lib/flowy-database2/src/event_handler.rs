use std::sync::Arc;

use collab_database::fields::Field;

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};

use crate::entities::*;
use crate::manager::DatabaseManager2;
use crate::services::field::type_option_data_from_bytes;

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_database_data_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<DatabasePB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database(view_id.as_ref()).await?;
  let data = database_editor.get_database_data().await;
  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_database_setting_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<DatabaseViewSettingPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database(view_id.as_ref()).await?;
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
  let editor = manager.get_database(&params.view_id).await?;

  if let Some(insert_params) = params.insert_group {
    editor.insert_group(insert_params).await?;
  }

  if let Some(delete_params) = params.delete_group {
    editor.delete_group(delete_params).await?;
  }

  if let Some(alter_filter) = params.insert_filter {
    editor.create_or_update_filter(alter_filter).await?;
  }

  if let Some(delete_filter) = params.delete_filter {
    editor.delete_filter(delete_filter).await?;
  }

  if let Some(alter_sort) = params.alert_sort {
    let _ = editor.create_or_update_sort(alter_sort).await?;
  }
  if let Some(delete_sort) = params.delete_sort {
    editor.delete_sort(delete_sort).await?;
  }
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_filters_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedFilterPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database(view_id.as_ref()).await?;
  let filters = database_editor.get_all_filters(view_id.as_ref()).await;
  data_result_ok(filters)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedSortPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database(view_id.as_ref()).await?;
  let sorts = database_editor.get_all_sorts(view_id.as_ref()).await;
  data_result_ok(sorts)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager.get_database(view_id.as_ref()).await?;
  database_editor.delete_all_sorts(view_id.as_ref()).await;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
  data: AFPluginData<GetFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedFieldPB, FlowyError> {
  let params: GetFieldParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database(&params.view_id).await?;
  let fields = database_editor
    .get_fields(&params.view_id, params.field_ids)
    .await;
  data_result_ok(fields)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_handler(
  data: AFPluginData<FieldChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: FieldChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database(&params.view_id).await?;
  database_editor.update_field(params).await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_type_option_handler(
  data: AFPluginData<TypeOptionChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: TypeOptionChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database(&params.view_id).await?;
  if let Some(old_field) = database_editor.get_field(&params.field_id) {
    let field_type = FieldType::from(old_field.field_type);
    let type_option_data = type_option_data_from_bytes(params.type_option_data, &field_type);
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
  let database_editor = manager.get_database(&params.view_id).await?;
  database_editor.delete_field(&params.field_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn switch_to_field_handler(
  data: AFPluginData<UpdateFieldTypePayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: EditFieldParams = data.into_inner().try_into()?;

  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
  data: AFPluginData<DuplicateFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: FieldIdParams = data.into_inner().try_into()?;
  Ok(())
}

/// Return the FieldTypeOptionData if the Field exists otherwise return record not found error.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_field_type_option_data_handler(
  data: AFPluginData<TypeOptionPathPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<TypeOptionPB, FlowyError> {
  let params: TypeOptionPathParams = data.into_inner().try_into()?;
  todo!()
}

/// Create FieldMeta and save it. Return the FieldTypeOptionData.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn create_field_type_option_data_handler(
  data: AFPluginData<CreateFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<TypeOptionPB, FlowyError> {
  let params: CreateFieldParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn move_field_handler(
  data: AFPluginData<MoveFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: MoveFieldParams = data.into_inner().try_into()?;
  Ok(())
}

/// The [Field] contains multiple data, each of them belongs to a specific FieldType.
async fn get_type_option_data(field_rev: &Field, field_type: &FieldType) -> FlowyResult<Vec<u8>> {
  todo!()
}

// #[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<OptionalRowPB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_row_handler(
  data: AFPluginData<MoveRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
  data: AFPluginData<CreateRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RowPB, FlowyError> {
  let params: CreateRowParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_cell_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<CellPB, FlowyError> {
  let params: CellIdParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_cell_handler(
  data: AFPluginData<CellChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let changeset: CellChangesetPB = data.into_inner();
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn new_select_option_handler(
  data: AFPluginData<CreateSelectOptionPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<SelectOptionPB, FlowyError> {
  let params: CreateSelectOptionParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_handler(
  data: AFPluginData<SelectOptionChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let changeset: SelectOptionChangeset = data.into_inner().try_into()?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_select_option_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<SelectOptionCellDataPB, FlowyError> {
  let params: CellIdParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_cell_handler(
  data: AFPluginData<SelectOptionCellChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;

  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_date_cell_handler(
  data: AFPluginData<DateChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> Result<(), FlowyError> {
  let data = data.into_inner();

  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_groups_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedGroupPB, FlowyError> {
  let params: DatabaseViewIdPB = data.into_inner();
  todo!()
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_group_handler(
  data: AFPluginData<DatabaseGroupIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<GroupPB, FlowyError> {
  let params: DatabaseGroupIdParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_handler(
  data: AFPluginData<MoveGroupPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: MoveGroupParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_row_handler(
  data: AFPluginData<MoveGroupRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  let params: MoveGroupRowParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn get_databases_handler(
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedDatabaseDescriptionPB, FlowyError> {
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn set_layout_setting_handler(
  data: AFPluginData<UpdateLayoutSettingPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> FlowyResult<()> {
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_layout_setting_handler(
  data: AFPluginData<DatabaseLayoutIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<LayoutSettingPB, FlowyError> {
  let params = data.into_inner();
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_calendar_events_handler(
  data: AFPluginData<CalendarEventRequestPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<RepeatedCalendarEventPB, FlowyError> {
  let params: CalendarEventRequestParams = data.into_inner().try_into()?;
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_calendar_event_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager2>>,
) -> DataResult<CalendarEventPB, FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  todo!()
}
