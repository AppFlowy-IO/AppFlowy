use crate::entities::*;
use crate::manager::DatabaseManager;
use crate::services::cell::{FromCellString, ToCellChangesetString, TypeCellData};
use crate::services::export::CSVExport;
use crate::services::field::{
  default_type_option_builder_from_type, select_type_option_from_field_rev,
  type_option_builder_from_json_str, DateCellChangeset, DateChangesetPB, SelectOptionCellChangeset,
  SelectOptionCellChangesetPB, SelectOptionCellChangesetParams, SelectOptionCellDataPB,
  SelectOptionChangeset, SelectOptionChangesetPB, SelectOptionIds, SelectOptionPB,
};
use crate::services::row::make_row_from_row_rev;
use database_model::FieldRevision;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use std::sync::Arc;

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_database_data_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<DatabasePB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let editor = manager.open_database_view(view_id.as_ref()).await?;
  let database = editor.get_database(view_id.as_ref()).await?;
  data_result_ok(database)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_database_setting_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<DatabaseViewSettingPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let editor = manager.open_database_view(view_id.as_ref()).await?;
  let database_setting = editor.get_setting(view_id.as_ref()).await?;
  data_result_ok(database_setting)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_database_setting_handler(
  data: AFPluginData<DatabaseSettingChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: DatabaseSettingChangesetParams = data.into_inner().try_into()?;

  let editor = manager.get_database_editor(&params.view_id).await?;
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
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<RepeatedFilterPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let editor = manager.open_database_view(view_id.as_ref()).await?;
  let filters = RepeatedFilterPB {
    items: editor.get_all_filters(view_id.as_ref()).await?,
  };
  data_result_ok(filters)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<RepeatedSortPB, FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let editor = manager.open_database_view(view_id.as_ref()).await?;
  let sorts = RepeatedSortPB {
    items: editor.get_all_sorts(view_id.as_ref()).await?,
  };
  data_result_ok(sorts)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let view_id: DatabaseViewIdPB = data.into_inner();
  let editor = manager.open_database_view(view_id.as_ref()).await?;
  editor.delete_all_sorts(view_id.as_ref()).await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
  data: AFPluginData<GetFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<RepeatedFieldPB, FlowyError> {
  let params: GetFieldParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  let field_revs = editor.get_field_revs(params.field_ids).await?;
  let repeated_field: RepeatedFieldPB = field_revs
    .into_iter()
    .map(FieldPB::from)
    .collect::<Vec<_>>()
    .into();
  data_result_ok(repeated_field)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_handler(
  data: AFPluginData<FieldChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let changeset: FieldChangesetParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&changeset.view_id).await?;
  editor.update_field(changeset).await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_type_option_handler(
  data: AFPluginData<TypeOptionChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: TypeOptionChangesetParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  let old_field_rev = editor.get_field_rev(&params.field_id).await;
  editor
    .update_field_type_option(
      &params.view_id,
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
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: FieldIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  editor.delete_field(&params.field_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn switch_to_field_handler(
  data: AFPluginData<UpdateFieldTypePayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: EditFieldParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
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
  editor
    .update_field_type_option(
      &params.view_id,
      &new_field_rev.id,
      type_option_data,
      old_field_rev,
    )
    .await?;

  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
  data: AFPluginData<DuplicateFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: FieldIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  editor.duplicate_field(&params.field_id).await?;
  Ok(())
}

/// Return the FieldTypeOptionData if the Field exists otherwise return record not found error.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_field_type_option_data_handler(
  data: AFPluginData<TypeOptionPathPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<TypeOptionPB, FlowyError> {
  let params: TypeOptionPathParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  match editor.get_field_rev(&params.field_id).await {
    None => Err(FlowyError::record_not_found()),
    Some(field_rev) => {
      let field_type = field_rev.ty.into();
      let type_option_data = get_type_option_data(&field_rev, &field_type).await?;
      let data = TypeOptionPB {
        view_id: params.view_id,
        field: field_rev.into(),
        type_option_data,
      };
      data_result_ok(data)
    },
  }
}

/// Create FieldMeta and save it. Return the FieldTypeOptionData.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn create_field_type_option_data_handler(
  data: AFPluginData<CreateFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<TypeOptionPB, FlowyError> {
  let params: CreateFieldParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  let field_rev = editor
    .create_new_field_rev_with_type_option(&params.field_type, params.type_option_data)
    .await?;
  let field_type: FieldType = field_rev.ty.into();
  let type_option_data = get_type_option_data(&field_rev, &field_type).await?;

  data_result_ok(TypeOptionPB {
    view_id: params.view_id,
    field: field_rev.into(),
    type_option_data,
  })
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn move_field_handler(
  data: AFPluginData<MoveFieldPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: MoveFieldParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  editor.move_field(params).await?;
  Ok(())
}

/// The [FieldRevision] contains multiple data, each of them belongs to a specific FieldType.
async fn get_type_option_data(
  field_rev: &FieldRevision,
  field_type: &FieldType,
) -> FlowyResult<Vec<u8>> {
  let s = field_rev
    .get_type_option_str(field_type)
    .map(|value| value.to_owned())
    .unwrap_or_else(|| {
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
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<OptionalRowPB, FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  let row = editor
    .get_row_rev(&params.row_id)
    .await?
    .map(make_row_from_row_rev);

  data_result_ok(OptionalRowPB { row })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  editor.delete_row(&params.row_id).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_row_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  editor
    .duplicate_row(&params.view_id, &params.row_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_row_handler(
  data: AFPluginData<MoveRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: MoveRowParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  editor.move_row(params).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
  data: AFPluginData<CreateRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<RowPB, FlowyError> {
  let params: CreateRowParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(params.view_id.as_ref()).await?;
  let row = editor.create_row(params).await?;
  data_result_ok(row)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_cell_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<CellPB, FlowyError> {
  let params: CellIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  match editor.get_cell(&params).await {
    None => data_result_ok(CellPB::empty(&params.field_id, &params.row_id)),
    Some(cell) => data_result_ok(cell),
  }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_cell_handler(
  data: AFPluginData<CellChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let changeset: CellChangesetPB = data.into_inner();
  let editor = manager.get_database_editor(&changeset.view_id).await?;
  editor
    .update_cell_with_changeset(
      &changeset.row_id,
      &changeset.field_id,
      changeset.type_cell_data,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn new_select_option_handler(
  data: AFPluginData<CreateSelectOptionPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<SelectOptionPB, FlowyError> {
  let params: CreateSelectOptionParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  match editor.get_field_rev(&params.field_id).await {
    None => Err(ErrorCode::InvalidData.into()),
    Some(field_rev) => {
      let type_option = select_type_option_from_field_rev(&field_rev)?;
      let select_option = type_option.create_option(&params.option_name);
      data_result_ok(select_option)
    },
  }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_handler(
  data: AFPluginData<SelectOptionChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let changeset: SelectOptionChangeset = data.into_inner().try_into()?;
  let editor = manager
    .get_database_editor(&changeset.cell_path.view_id)
    .await?;
  let field_id = changeset.cell_path.field_id.clone();
  let (tx, rx) = tokio::sync::oneshot::channel();
  editor
    .modify_field_rev(&changeset.cell_path.view_id, &field_id, |field_rev| {
      let mut type_option = select_type_option_from_field_rev(field_rev)?;
      let mut cell_changeset_str = None;
      let mut is_changed = None;

      for option in changeset.insert_options {
        cell_changeset_str = Some(
          SelectOptionCellChangeset::from_insert_option_id(&option.id).to_cell_changeset_str(),
        );
        type_option.insert_option(option);
        is_changed = Some(());
      }

      for option in changeset.update_options {
        type_option.insert_option(option);
        is_changed = Some(());
      }

      for option in changeset.delete_options {
        cell_changeset_str = Some(
          SelectOptionCellChangeset::from_delete_option_id(&option.id).to_cell_changeset_str(),
        );
        type_option.delete_option(option);
        is_changed = Some(());
      }

      if is_changed.is_some() {
        field_rev.insert_type_option(&*type_option);
      }
      let _ = tx.send(cell_changeset_str);
      Ok(is_changed)
    })
    .await?;

  if let Ok(Some(cell_changeset_str)) = rx.await {
    match editor
      .update_cell_with_changeset(
        &changeset.cell_path.row_id,
        &changeset.cell_path.field_id,
        cell_changeset_str,
      )
      .await
    {
      Ok(_) => {},
      Err(e) => tracing::error!("{}", e),
    }
  }
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_select_option_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<SelectOptionCellDataPB, FlowyError> {
  let params: CellIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  match editor.get_field_rev(&params.field_id).await {
    None => {
      tracing::error!(
        "Can't find the select option field with id: {}",
        params.field_id
      );
      data_result_ok(SelectOptionCellDataPB::default())
    },
    Some(field_rev) => {
      //
      let cell_rev = editor
        .get_cell_rev(&params.row_id, &params.field_id)
        .await?;
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
      data_result_ok(selected_options)
    },
  }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_cell_handler(
  data: AFPluginData<SelectOptionCellChangesetPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;
  let editor = manager
    .get_database_editor(&params.cell_identifier.view_id)
    .await?;
  let changeset = SelectOptionCellChangeset {
    insert_option_ids: params.insert_option_ids,
    delete_option_ids: params.delete_option_ids,
  };

  editor
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
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let data = data.into_inner();
  let cell_path: CellIdParams = data.cell_path.try_into()?;
  let cell_changeset = DateCellChangeset {
    date: data.date,
    time: data.time,
    include_time: data.include_time,
    is_utc: data.is_utc,
  };

  let editor = manager.get_database_editor(&cell_path.view_id).await?;
  editor
    .update_cell(cell_path.row_id, cell_path.field_id, cell_changeset)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_groups_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<RepeatedGroupPB, FlowyError> {
  let params: DatabaseViewIdPB = data.into_inner();
  let editor = manager.get_database_editor(&params.value).await?;
  let groups = editor.load_groups(&params.value).await?;
  data_result_ok(groups)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_group_handler(
  data: AFPluginData<DatabaseGroupIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<GroupPB, FlowyError> {
  let params: DatabaseGroupIdParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(&params.view_id).await?;
  let group = editor.get_group(&params.view_id, &params.group_id).await?;
  data_result_ok(group)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_handler(
  data: AFPluginData<MoveGroupPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> FlowyResult<()> {
  let params: MoveGroupParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(params.view_id.as_ref()).await?;
  editor.move_group(params).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_row_handler(
  data: AFPluginData<MoveGroupRowPayloadPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> FlowyResult<()> {
  let params: MoveGroupRowParams = data.into_inner().try_into()?;
  let editor = manager.get_database_editor(params.view_id.as_ref()).await?;
  editor.move_group_row(params).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn get_databases_handler(
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<RepeatedDatabaseDescriptionPB, FlowyError> {
  let items = manager
    .get_databases()
    .await?
    .into_iter()
    .map(|database_info| DatabaseDescriptionPB {
      name: database_info.name,
      database_id: database_info.database_id,
    })
    .collect::<Vec<DatabaseDescriptionPB>>();
  data_result_ok(RepeatedDatabaseDescriptionPB { items })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn set_layout_setting_handler(
  data: AFPluginData<UpdateLayoutSettingPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> FlowyResult<()> {
  let params: UpdateLayoutSettingParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_editor(params.view_id.as_ref()).await?;
  database_editor
    .set_layout_setting(&params.view_id, params.layout_setting)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_layout_setting_handler(
  data: AFPluginData<DatabaseLayoutIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<LayoutSettingPB, FlowyError> {
  let params = data.into_inner();
  let database_editor = manager.get_database_editor(&params.view_id).await?;
  let layout_setting = database_editor
    .get_layout_setting(&params.view_id, params.layout)
    .await?;
  data_result_ok(layout_setting.into())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_calendar_events_handler(
  data: AFPluginData<CalendarEventRequestPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<RepeatedCalendarEventPB, FlowyError> {
  let params: CalendarEventRequestParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_editor(&params.view_id).await?;
  let events = database_editor
    .get_all_calendar_events(&params.view_id)
    .await;
  data_result_ok(RepeatedCalendarEventPB { items: events })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_calendar_event_handler(
  data: AFPluginData<RowIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<CalendarEventPB, FlowyError> {
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager.get_database_editor(&params.view_id).await?;
  let event = database_editor
    .get_calendar_event(&params.view_id, &params.row_id)
    .await;
  match event {
    None => Err(FlowyError::record_not_found()),
    Some(event) => data_result_ok(event),
  }
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn export_csv_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Arc<DatabaseManager>>,
) -> DataResult<ExportCSVPB, FlowyError> {
  let params = data.into_inner();
  let database_editor = manager.get_database_editor(&params.value).await?;
  let content = CSVExport
    .export_database(&params.value, &database_editor)
    .await?;
  data_result_ok(ExportCSVPB { data: content })
}
