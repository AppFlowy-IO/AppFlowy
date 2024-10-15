use collab_database::fields::media_type_option::MediaCellData;
use collab_database::rows::{Cell, CoverType, RowCover, RowId};
use lib_infra::box_any::BoxAny;
use std::sync::{Arc, Weak};
use tokio::sync::oneshot;
use tracing::{info, instrument};

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{af_spawn, data_result_ok, AFPluginData, AFPluginState, DataResult};

use crate::entities::*;
use crate::manager::DatabaseManager;
use crate::services::field::{
  type_option_data_from_pb, ChecklistCellChangeset, DateCellChangeset, RelationCellChangeset,
  SelectOptionCellChangeset, TypeOptionCellExt,
};
use crate::services::group::GroupChangeset;
use crate::services::share::csv::CSVFormat;

fn upgrade_manager(
  database_manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<Arc<DatabaseManager>> {
  let manager = database_manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The database manager is already dropped"))?;
  Ok(manager)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_database_data_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<DatabasePB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_id = manager
    .get_database_id_with_view_id(view_id.as_ref())
    .await?;
  let database_editor = manager.get_or_init_database_editor(&database_id).await?;
  let start = std::time::Instant::now();
  let data = database_editor
    .open_database_view(view_id.as_ref(), None)
    .await?;
  info!(
    "[Database]: {} layout: {:?}, rows: {}, fields: {}, cost time: {} milliseconds",
    database_id,
    data.layout_type,
    data.rows.len(),
    data.fields.len(),
    start.elapsed().as_millis()
  );
  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_all_rows_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedRowMetaPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_id = manager
    .get_database_id_with_view_id(view_id.as_ref())
    .await?;
  let database_editor = manager.get_or_init_database_editor(&database_id).await?;
  let row_details = database_editor.get_all_rows(view_id.as_ref()).await?;
  let rows = row_details
    .into_iter()
    .map(|detail| RowMetaPB::from(detail.as_ref()))
    .collect::<Vec<RowMetaPB>>();
  data_result_ok(RepeatedRowMetaPB { items: rows })
}
#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn open_database_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_id = manager
    .get_database_id_with_view_id(view_id.as_ref())
    .await?;
  let _ = manager.open_database(&database_id).await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_database_id_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<DatabaseIdPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_id = manager
    .get_database_id_with_view_id(view_id.as_ref())
    .await?;
  data_result_ok(DatabaseIdPB { value: database_id })
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_database_setting_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<DatabaseViewSettingPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(view_id.as_ref())
    .await?;
  let data = database_editor
    .get_database_view_setting(view_id.as_ref())
    .await?;
  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_database_setting_handler(
  data: AFPluginData<DatabaseSettingChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;

  if let Some(payload) = params.insert_filter {
    database_editor
      .modify_view_filters(&params.view_id, payload.try_into()?)
      .await?;
  }

  if let Some(payload) = params.update_filter_type {
    database_editor
      .modify_view_filters(&params.view_id, payload.try_into()?)
      .await?;
  }

  if let Some(payload) = params.update_filter_data {
    database_editor
      .modify_view_filters(&params.view_id, payload.try_into()?)
      .await?;
  }

  if let Some(payload) = params.delete_filter {
    database_editor
      .modify_view_filters(&params.view_id, payload.into())
      .await?;
  }

  if let Some(update_sort) = params.update_sort {
    let _ = database_editor.create_or_update_sort(update_sort).await?;
  }

  if let Some(reorder_sort) = params.reorder_sort {
    database_editor.reorder_sort(reorder_sort).await?;
  }

  if let Some(delete_sort) = params.delete_sort {
    database_editor.delete_sort(delete_sort).await?;
  }

  if let Some(layout_type) = params.layout_type {
    database_editor
      .update_view_layout(&params.view_id, layout_type.into())
      .await?;
  }
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_filters_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedFilterPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(view_id.as_ref())
    .await?;
  let filters = database_editor.get_all_filters(view_id.as_ref()).await;
  data_result_ok(filters)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedSortPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(view_id.as_ref())
    .await?;
  let sorts = database_editor.get_all_sorts(view_id.as_ref()).await;
  data_result_ok(sorts)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_all_sorts_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(view_id.as_ref())
    .await?;
  database_editor.delete_all_sorts(view_id.as_ref()).await;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_fields_handler(
  data: AFPluginData<GetFieldPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedFieldPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: GetFieldParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let fields = database_editor
    .get_fields(&params.view_id, params.field_ids)
    .await
    .into_iter()
    .map(FieldPB::new)
    .collect::<Vec<FieldPB>>()
    .into();
  data_result_ok(fields)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn get_primary_field_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<FieldPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id = data.into_inner().value;
  let database_editor = manager.get_database_editor_with_view_id(&view_id).await?;
  let mut fields = database_editor
    .get_fields(&view_id, None)
    .await
    .into_iter()
    .filter(|field| field.is_primary)
    .map(FieldPB::new)
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
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor.update_field(params).await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_field_type_option_handler(
  data: AFPluginData<TypeOptionChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: TypeOptionChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  if let Some(old_field) = database_editor.get_field(&params.field_id).await {
    let field_type = FieldType::from(old_field.field_type);
    let type_option_data = type_option_data_from_pb(params.type_option_data, &field_type)?;
    database_editor
      .update_field_type_option(&params.field_id, type_option_data, old_field)
      .await?;
  }
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn delete_field_handler(
  data: AFPluginData<DeleteFieldPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: FieldIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor.delete_field(&params.field_id).await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn clear_field_handler(
  data: AFPluginData<ClearFieldPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: FieldIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .clear_field(&params.view_id, &params.field_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn switch_to_field_handler(
  data: AFPluginData<UpdateFieldTypePayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: EditFieldParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .switch_to_field_type(
      &params.view_id,
      &params.field_id,
      params.field_type,
      params.field_name,
    )
    .await?;

  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn duplicate_field_handler(
  data: AFPluginData<DuplicateFieldPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: DuplicateFieldPayloadPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .duplicate_field(&params.view_id, &params.field_id)
    .await?;
  Ok(())
}

/// Create a field and save it. Returns the [FieldPB] in the current view.
#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn create_field_handler(
  data: AFPluginData<CreateFieldPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<FieldPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: CreateFieldParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let data = database_editor
    .create_field_with_type_option(params)
    .await?;

  data_result_ok(data)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn move_field_handler(
  data: AFPluginData<MoveFieldPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: MoveFieldParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor.move_field(params).await?;
  Ok(())
}

// #[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_row_handler(
  data: AFPluginData<DatabaseViewRowIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<OptionalRowPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let row = database_editor
    .get_row(&params.view_id, &params.row_id)
    .await
    .map(RowPB::from);
  data_result_ok(OptionalRowPB { row })
}

pub(crate) async fn init_row_handler(
  data: AFPluginData<DatabaseViewRowIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor.init_database_row(&params.row_id).await?;
  Ok(())
}

pub(crate) async fn get_row_meta_handler(
  data: AFPluginData<DatabaseViewRowIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RowMetaPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  match database_editor
    .get_row_meta(&params.view_id, &params.row_id)
    .await
  {
    None => Err(FlowyError::record_not_found()),
    Some(row) => data_result_ok(row),
  }
}

pub(crate) async fn update_row_meta_handler(
  data: AFPluginData<UpdateRowMetaChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: UpdateRowMetaParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let row_id = RowId::from(params.id.clone());
  database_editor
    .update_row_meta(&row_id.clone(), params)
    .await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn delete_rows_handler(
  data: AFPluginData<RepeatedRowIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RepeatedRowIdPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let row_ids = params
    .row_ids
    .into_iter()
    .map(RowId::from)
    .collect::<Vec<_>>();
  database_editor.delete_rows(&row_ids).await;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn duplicate_row_handler(
  data: AFPluginData<DatabaseViewRowIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .duplicate_row(&params.view_id, &params.row_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_row_handler(
  data: AFPluginData<MoveRowPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: MoveRowParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .move_row(&params.view_id, params.from_row_id, params.to_row_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn remove_cover_handler(
  data: AFPluginData<RemoveCoverPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RemoveCoverParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;

  let update_row_changeset = UpdateRowMetaParams {
    id: params.row_id.clone().into(),
    view_id: params.view_id.clone(),
    cover: Some(RowCover::default()),
    ..Default::default()
  };

  database_editor
    .update_row_meta(&params.row_id, update_row_changeset)
    .await;

  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn create_row_handler(
  data: AFPluginData<CreateRowPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RowMetaPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;

  match database_editor.create_row(params).await? {
    Some(row) => data_result_ok(RowMetaPB::from(row)),
    None => Err(FlowyError::internal().with_context("Error creating row")),
  }
}

// #[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_cell_handler(
  data: AFPluginData<CellIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<CellPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: CellIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let cell = database_editor
    .get_cell_pb(&params.field_id, &params.row_id)
    .await
    .unwrap_or_else(|| CellPB::empty(&params.field_id, params.row_id.into_inner()));
  data_result_ok(cell)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_cell_handler(
  data: AFPluginData<CellChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: CellChangesetPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .update_cell_with_changeset(
      &params.view_id,
      &RowId::from(params.row_id),
      &params.field_id,
      BoxAny::new(params.cell_changeset),
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn new_select_option_handler(
  data: AFPluginData<CreateSelectOptionPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<SelectOptionPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: CreateSelectOptionParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let result = database_editor
    .create_select_option(&params.field_id, params.option_name)
    .await;
  match result {
    None => Err(
      FlowyError::record_not_found()
        .with_context("Create select option fail. Can't find the field"),
    ),
    Some(pb) => data_result_ok(pb),
  }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn insert_or_update_select_option_handler(
  data: AFPluginData<RepeatedSelectOptionPayload>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
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
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
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

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_select_option_cell_handler(
  data: AFPluginData<SelectOptionCellChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: SelectOptionCellChangesetParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.cell_identifier.view_id)
    .await?;
  let changeset = SelectOptionCellChangeset {
    insert_option_ids: params.insert_option_ids,
    delete_option_ids: params.delete_option_ids,
  };
  database_editor
    .update_cell_with_changeset(
      &params.cell_identifier.view_id,
      &params.cell_identifier.row_id,
      &params.cell_identifier.field_id,
      BoxAny::new(changeset),
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_checklist_cell_handler(
  data: AFPluginData<ChecklistCellDataChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.cell_id.view_id)
    .await?;

  let cell_id = params.cell_id.clone();

  database_editor
    .update_cell_with_changeset(
      &cell_id.view_id,
      &(RowId::from(cell_id.row_id)),
      &cell_id.field_id,
      BoxAny::new(ChecklistCellChangeset::from(params)),
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_date_cell_handler(
  data: AFPluginData<DateCellChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let data = data.into_inner();
  let cell_id: CellIdParams = data.cell_id.try_into()?;
  let cell_changeset = DateCellChangeset {
    date: data.date,
    time: data.time,
    end_date: data.end_date,
    end_time: data.end_time,
    include_time: data.include_time,
    is_range: data.is_range,
    clear_flag: data.clear_flag,
    reminder_id: data.reminder_id,
  };

  let database_editor = manager
    .get_database_editor_with_view_id(&cell_id.view_id)
    .await?;
  database_editor
    .update_cell_with_changeset(
      &cell_id.view_id,
      &cell_id.row_id,
      &cell_id.field_id,
      BoxAny::new(cell_changeset),
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_groups_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedGroupPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: DatabaseViewIdPB = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(params.as_ref())
    .await?;
  let groups = database_editor.load_groups(params.as_ref()).await?;
  data_result_ok(groups)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn get_group_handler(
  data: AFPluginData<DatabaseGroupIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<GroupPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: DatabaseGroupIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let group = database_editor
    .get_group(&params.view_id, &params.group_id)
    .await?;
  data_result_ok(group)
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn set_group_by_field_handler(
  data: AFPluginData<GroupByFieldPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: GroupByFieldParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .set_group_by_field(&params.view_id, &params.field_id, params.setting_content)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub(crate) async fn update_group_handler(
  data: AFPluginData<UpdateGroupPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: UpdateGroupParams = data.into_inner().try_into()?;
  let view_id = params.view_id.clone();
  let database_editor = manager.get_database_editor_with_view_id(&view_id).await?;
  let group_changeset = GroupChangeset::from(params);
  database_editor
    .update_group(&view_id, vec![group_changeset])
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_handler(
  data: AFPluginData<MoveGroupPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: MoveGroupParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .move_group(&params.view_id, &params.from_group_id, &params.to_group_id)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn move_group_row_handler(
  data: AFPluginData<MoveGroupRowPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: MoveGroupRowParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .move_group_row(
      &params.view_id,
      &params.from_group_id,
      &params.to_group_id,
      params.from_row_id,
      params.to_row_id,
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn create_group_handler(
  data: AFPluginData<CreateGroupPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: CreateGroupParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .create_group(&params.view_id, &params.name)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn delete_group_handler(
  data: AFPluginData<DeleteGroupPayloadPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: DeleteGroupParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor.delete_group(params).await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn get_database_meta_handler(
  data: AFPluginData<DatabaseIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<DatabaseMetaPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let database_id = data.into_inner().value;
  let inline_view_id = manager.get_database_inline_view_id(&database_id).await?;

  let data = DatabaseMetaPB {
    database_id,
    inline_view_id,
  };
  data_result_ok(data)
}

#[tracing::instrument(level = "debug", skip(manager), err)]
pub(crate) async fn get_databases_handler(
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedDatabaseDescriptionPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let metas = manager.get_all_databases_meta().await;

  let mut items = Vec::with_capacity(metas.len());
  for meta in metas {
    if let Some(link_view) = meta.linked_views.first() {
      items.push(DatabaseMetaPB {
        database_id: meta.database_id,
        inline_view_id: link_view.clone(),
      })
    }
  }

  let data = RepeatedDatabaseDescriptionPB { items };
  data_result_ok(data)
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn set_layout_setting_handler(
  data: AFPluginData<LayoutSettingChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let changeset = data.into_inner();
  let view_id = changeset.view_id.clone();
  let params: LayoutSettingChangeset = changeset.try_into()?;
  let database_editor = manager.get_database_editor_with_view_id(&view_id).await?;
  database_editor.set_layout_setting(&view_id, params).await?;
  Ok(())
}
pub(crate) async fn get_layout_setting_handler(
  data: AFPluginData<DatabaseLayoutMetaPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<DatabaseLayoutSettingPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: DatabaseLayoutMeta = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
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
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedCalendarEventPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: CalendarEventRequestParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let events = database_editor
    .get_all_calendar_events(&params.view_id)
    .await;
  data_result_ok(RepeatedCalendarEventPB { items: events })
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_no_date_calendar_events_handler(
  data: AFPluginData<CalendarEventRequestPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedNoDateCalendarEventPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: CalendarEventRequestParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  let _events = database_editor
    .get_all_no_date_calendar_events(&params.view_id)
    .await;
  todo!()
}

#[tracing::instrument(level = "debug", skip(data, manager), err)]
pub(crate) async fn get_calendar_event_handler(
  data: AFPluginData<DatabaseViewRowIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<CalendarEventPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RowIdParams = data.into_inner().try_into()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
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
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let data = data.into_inner();
  let cell_id: CellIdParams = data.cell_path.try_into()?;
  let cell_changeset = DateCellChangeset {
    date: Some(data.timestamp),
    ..Default::default()
  };
  let database_editor = manager
    .get_database_editor_with_view_id(&cell_id.view_id)
    .await?;
  database_editor
    .update_cell_with_changeset(
      &cell_id.view_id,
      &cell_id.row_id,
      &cell_id.field_id,
      BoxAny::new(cell_changeset),
    )
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn create_database_view(
  _data: AFPluginData<CreateDatabaseViewPayloadPB>,
  _manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  // let data: CreateDatabaseViewParams = data.into_inner().try_into()?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn export_csv_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<DatabaseExportDataPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id = data.into_inner().value;
  let database = manager.get_database_editor_with_view_id(&view_id).await?;
  let data = database.export_csv(CSVFormat::Original).await?;
  data_result_ok(DatabaseExportDataPB {
    export_type: DatabaseExportDataType::CSV,
    data,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn export_raw_database_data_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<DatabaseExportDataPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id = data.into_inner().value;
  let data = manager.get_database_json_string(&view_id).await?;
  data_result_ok(DatabaseExportDataPB {
    export_type: DatabaseExportDataType::RawDatabaseData,
    data,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_snapshots_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedDatabaseSnapshotPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id = data.into_inner().value;
  let snapshots = manager.get_database_snapshots(&view_id, 10).await?;
  data_result_ok(RepeatedDatabaseSnapshotPB { items: snapshots })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_field_settings_handler(
  data: AFPluginData<FieldIdsPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedFieldSettingsPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let (view_id, field_ids) = data.into_inner().try_into()?;
  let database_editor = manager.get_database_editor_with_view_id(&view_id).await?;

  let field_settings = database_editor
    .get_field_settings(&view_id, field_ids.clone())
    .await?
    .into_iter()
    .map(FieldSettingsPB::from)
    .collect();

  data_result_ok(RepeatedFieldSettingsPB {
    items: field_settings,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_all_field_settings_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedFieldSettingsPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(view_id.as_ref())
    .await?;

  let field_settings = database_editor
    .get_all_field_settings(view_id.as_ref())
    .await?
    .into_iter()
    .map(FieldSettingsPB::from)
    .collect();

  data_result_ok(RepeatedFieldSettingsPB {
    items: field_settings,
  })
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_field_settings_handler(
  data: AFPluginData<FieldSettingsChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params = data.try_into_inner()?;
  let database_editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;
  database_editor
    .update_field_settings_with_changeset(params)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_all_calculations_handler(
  data: AFPluginData<DatabaseViewIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedCalculationsPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let view_id = data.into_inner();
  let database_editor = manager
    .get_database_editor_with_view_id(view_id.as_ref())
    .await?;

  let calculations = database_editor.get_all_calculations(view_id.as_ref()).await;

  data_result_ok(calculations)
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn update_calculation_handler(
  data: AFPluginData<UpdateCalculationChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: UpdateCalculationChangesetPB = data.into_inner();
  let editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;

  editor.update_calculation(params).await?;

  Ok(())
}

#[tracing::instrument(level = "trace", skip(data, manager), err)]
pub(crate) async fn remove_calculation_handler(
  data: AFPluginData<RemoveCalculationChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: RemoveCalculationChangesetPB = data.into_inner();
  let editor = manager
    .get_database_editor_with_view_id(&params.view_id)
    .await?;

  editor.remove_calculation(params).await?;

  Ok(())
}

pub(crate) async fn get_related_database_ids_handler(
  _data: AFPluginData<DatabaseViewIdPB>,
  _manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_relation_cell_handler(
  data: AFPluginData<RelationCellChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: RelationCellChangesetPB = data.into_inner();
  let view_id = parser::NotEmptyStr::parse(params.view_id)
    .map_err(|_| flowy_error::ErrorCode::DatabaseViewIdIsEmpty)?
    .0;
  let cell_id: CellIdParams = params.cell_id.try_into()?;
  let params = RelationCellChangeset {
    inserted_row_ids: params
      .inserted_row_ids
      .into_iter()
      .map(Into::into)
      .collect(),
    removed_row_ids: params.removed_row_ids.into_iter().map(Into::into).collect(),
  };

  let database_editor = manager.get_database_editor_with_view_id(&view_id).await?;

  // // get the related database
  // let related_database_id = database_editor
  //   .get_related_database_id(&cell_id.field_id)
  //   .await?;
  // let related_database_editor = manager.get_database(&related_database_id).await?;

  // // validate the changeset contents
  // related_database_editor
  //   .validate_row_ids_exist(&params)
  //   .await?;

  // update the cell in the database
  database_editor
    .update_cell_with_changeset(
      &view_id,
      &cell_id.row_id,
      &cell_id.field_id,
      BoxAny::new(params),
    )
    .await?;
  Ok(())
}

#[instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_related_row_datas_handler(
  data: AFPluginData<GetRelatedRowDataPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedRelatedRowDataPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let params: GetRelatedRowDataPB = data.into_inner();
  let database_editor = manager
    .get_or_init_database_editor(&params.database_id)
    .await?;

  let row_datas = database_editor
    .get_related_rows(Some(params.row_ids))
    .await?;

  data_result_ok(RepeatedRelatedRowDataPB { rows: row_datas })
}

#[instrument(level = "debug", skip_all, err)]
pub(crate) async fn get_related_database_rows_handler(
  data: AFPluginData<DatabaseIdPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> DataResult<RepeatedRelatedRowDataPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let database_id = data.into_inner().value;

  info!(
    "[Database]: get related database rows from database_id: {}",
    database_id
  );
  let database_editor = manager.get_or_init_database_editor(&database_id).await?;
  let rows = database_editor.get_related_rows(None).await?;
  data_result_ok(RepeatedRelatedRowDataPB { rows })
}

pub(crate) async fn summarize_row_handler(
  data: AFPluginData<SummaryRowPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let data = data.into_inner();
  let row_id = RowId::from(data.row_id);
  let (tx, rx) = oneshot::channel();
  af_spawn(async move {
    let result = manager
      .summarize_row(data.view_id, row_id, data.field_id)
      .await;
    let _ = tx.send(result);
  });

  rx.await??;
  Ok(())
}

pub(crate) async fn translate_row_handler(
  data: AFPluginData<TranslateRowPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> Result<(), FlowyError> {
  let manager = upgrade_manager(manager)?;
  let data = data.try_into_inner()?;
  let row_id = RowId::from(data.row_id);
  let (tx, rx) = oneshot::channel();
  af_spawn(async move {
    let result = manager
      .translate_row(data.view_id, row_id, data.field_id)
      .await;
    let _ = tx.send(result);
  });

  rx.await??;
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn update_media_cell_handler(
  data: AFPluginData<MediaCellChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: MediaCellChangesetPB = data.into_inner();
  let cell_id: CellIdParams = params.cell_id.try_into()?;
  let cell_changeset = MediaCellChangeset {
    inserted_files: params
      .inserted_files
      .clone()
      .into_iter()
      .map(Into::into)
      .collect(),
    removed_ids: params.removed_ids,
  };

  let database_editor = manager
    .get_database_editor_with_view_id(&cell_id.view_id)
    .await?;

  database_editor
    .update_cell_with_changeset(
      &cell_id.view_id,
      &cell_id.row_id,
      &cell_id.field_id,
      BoxAny::new(cell_changeset),
    )
    .await?;

  let image_file = params
    .inserted_files
    .iter()
    .find(|file| file.file_type == MediaFileTypePB::Image);
  let row_meta = database_editor
    .get_row_meta(&cell_id.view_id, &cell_id.row_id)
    .await;

  if let (Some(row_meta), Some(file)) = (row_meta, image_file) {
    let row_meta = row_meta.clone();
    if row_meta.cover.is_none() {
      let update_row_meta = UpdateRowMetaParams {
        id: cell_id.row_id.clone().into(),
        view_id: cell_id.view_id.clone(),
        cover: Some(RowCover {
          data: file.url.clone(),
          upload_type: file.upload_type.into(),
          cover_type: CoverType::FileCover,
        }),
        ..UpdateRowMetaParams::default()
      };

      database_editor
        .update_row_meta(&cell_id.row_id, update_row_meta)
        .await;
    }
  }

  Ok(())
}

/// We use a custom handler to rename the media file, as the ordering
/// of the files must be maintained while renaming a file.
///
/// The changeset in [update_media_cell_handler] contains removals and inserts,
/// and if we were to remove and insert the file, it would mess up the ordering.
///
#[tracing::instrument(level = "debug", skip_all, err)]
pub(crate) async fn rename_media_cell_file_handler(
  data: AFPluginData<RenameMediaChangesetPB>,
  manager: AFPluginState<Weak<DatabaseManager>>,
) -> FlowyResult<()> {
  let manager = upgrade_manager(manager)?;
  let params: RenameMediaChangesetPB = data.into_inner();
  let cell_id: CellIdParams = params.cell_id.try_into()?;

  let database_editor = manager
    .get_database_editor_with_view_id(&cell_id.view_id)
    .await?;

  let cell = database_editor
    .get_cell(&cell_id.field_id, &cell_id.row_id)
    .await;
  if cell.is_none() {
    return Err(FlowyError::record_not_found());
  }

  let cell = cell.unwrap();
  let field = database_editor
    .get_field(&cell_id.field_id)
    .await
    .ok_or_else(FlowyError::record_not_found)?;
  let handler = TypeOptionCellExt::new(&field, None)
    .get_type_option_cell_data_handler_with_field_type(FieldType::Media);
  if handler.is_none() {
    return Err(
      FlowyError::internal().with_context("Error renaming media file: field type is not Media"),
    );
  }
  let handler = handler.unwrap();
  let data = handler
    .handle_get_boxed_cell_data(&cell, &field)
    .and_then(|cell_data| cell_data.unbox_or_none())
    .unwrap_or_else(MediaCellData::default);

  let file = data
    .files
    .iter()
    .find(|file| file.id == params.file_id)
    .ok_or_else(FlowyError::record_not_found)?;

  let new_file = file.rename(params.name);
  let new_data = MediaCellData {
    files: data
      .files
      .iter()
      .map(|file| {
        if file.id == params.file_id {
          new_file.clone()
        } else {
          file.clone()
        }
      })
      .collect(),
  };

  let result = database_editor
    .update_cell(
      &cell_id.view_id,
      &cell_id.row_id,
      &cell_id.field_id,
      Cell::from(new_data),
    )
    .await;

  if result.is_err() {
    return Err(
      FlowyError::internal().with_context("Error renaming media file: update cell failed"),
    );
  }

  Ok(())
}
