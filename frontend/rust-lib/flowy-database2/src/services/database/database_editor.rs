use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

use bytes::Bytes;
use collab_database::database::Database as InnerDatabase;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, Cells, CreateRowParams, Row, RowCell, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting};
use parking_lot::Mutex;
use tokio::sync::{broadcast, RwLock};

use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::{to_fut, Fut};

use crate::entities::{
  CalendarEventPB, CellChangesetNotifyPB, CellPB, ChecklistCellDataPB, DatabaseFieldChangesetPB,
  DatabasePB, DatabaseViewSettingPB, DeleteFilterParams, DeleteGroupParams, DeleteSortParams,
  FieldChangesetParams, FieldIdPB, FieldPB, FieldType, GroupPB, IndexFieldPB, InsertedRowPB,
  LayoutSettingParams, NoDateCalendarEventPB, RepeatedFilterPB, RepeatedGroupPB, RepeatedSortPB,
  RowPB, RowsChangePB, SelectOptionCellDataPB, SelectOptionPB, UpdateFilterParams,
  UpdateSortParams, UpdatedRowPB,
};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::{
  apply_cell_changeset, get_cell_protobuf, AnyTypeCache, CellCache, ToCellChangeset,
};
use crate::services::database::util::database_view_setting_pb_from_view;
use crate::services::database_view::{DatabaseViewChanged, DatabaseViewData, DatabaseViews};
use crate::services::field::checklist_type_option::{ChecklistCellChangeset, ChecklistCellData};
use crate::services::field::{
  default_type_option_data_from_type, select_type_option_from_field, transform_type_option,
  type_option_data_from_pb_or_default, type_option_to_pb, DateCellData, SelectOptionCellChangeset,
  SelectOptionIds, TypeOptionCellDataHandler, TypeOptionCellExt,
};
use crate::services::filter::Filter;
use crate::services::group::{
  default_group_setting, GroupSetting, GroupSettingChangeset, RowChangeset,
};
use crate::services::share::csv::{CSVExport, CSVFormat};
use crate::services::sort::Sort;

#[derive(Clone)]
pub struct DatabaseEditor {
  database: MutexDatabase,
  pub cell_cache: CellCache,
  database_views: Arc<DatabaseViews>,
}

impl DatabaseEditor {
  pub async fn new(
    database: MutexDatabase,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Self> {
    let cell_cache = AnyTypeCache::<u64>::new();
    let database_view_data = Arc::new(DatabaseViewDataImpl {
      database: database.clone(),
      task_scheduler: task_scheduler.clone(),
      cell_cache: cell_cache.clone(),
    });

    let database_views =
      Arc::new(DatabaseViews::new(database.clone(), cell_cache.clone(), database_view_data).await?);
    Ok(Self {
      database,
      cell_cache,
      database_views,
    })
  }

  #[tracing::instrument(level = "debug", skip_all)]
  pub async fn close_view_editor(&self, view_id: &str) -> bool {
    self.database_views.close_view(view_id).await
  }

  pub async fn close(&self) {}

  pub async fn update_view_layout(
    &self,
    view_id: &str,
    layout_type: DatabaseLayout,
  ) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_update_layout_type(layout_type).await?;

    Ok(())
  }

  pub async fn subscribe_view_changed(
    &self,
    view_id: &str,
  ) -> FlowyResult<broadcast::Receiver<DatabaseViewChanged>> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    Ok(view_editor.notifier.subscribe())
  }

  pub fn get_field(&self, field_id: &str) -> Option<Field> {
    self.database.lock().fields.get_field(field_id)
  }

  pub async fn set_group_by_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    {
      let database = self.database.lock();
      let field = database.fields.get_field(field_id);
      if let Some(field) = field {
        let group_setting = default_group_setting(&field);
        database.insert_group_setting(view_id, group_setting);
      }
    }

    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_initialize_new_group(field_id).await?;
    Ok(())
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .delete_group_setting(&params.view_id, &params.group_id);
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_group(params).await?;

    Ok(())
  }

  /// Returns the delete view ids.
  /// If the view is inline view, all the reference views will be deleted. So the return value
  /// will be the reference view ids and the inline view id. Otherwise, the return value will
  /// be the view id.
  pub async fn delete_database_view(&self, view_id: &str) -> FlowyResult<Vec<String>> {
    Ok(self.database.lock().delete_view(view_id))
  }

  pub async fn update_group_setting(
    &self,
    view_id: &str,
    group_setting_changeset: GroupSettingChangeset,
  ) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor
      .update_group_setting(group_setting_changeset)
      .await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn create_or_update_filter(&self, params: UpdateFilterParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_insert_filter(params).await?;
    Ok(())
  }

  pub async fn delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_filter(params).await?;
    Ok(())
  }

  pub async fn create_or_update_sort(&self, params: UpdateSortParams) -> FlowyResult<Sort> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    let sort = view_editor.v_insert_sort(params).await?;
    Ok(sort)
  }

  pub async fn delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_sort(params).await?;
    Ok(())
  }

  pub async fn get_all_filters(&self, view_id: &str) -> RepeatedFilterPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      view_editor.v_get_all_filters().await.into()
    } else {
      RepeatedFilterPB { items: vec![] }
    }
  }

  pub async fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter> {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      Some(view_editor.v_get_filter(filter_id).await?)
    } else {
      None
    }
  }
  pub async fn get_all_sorts(&self, view_id: &str) -> RepeatedSortPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      view_editor.v_get_all_sorts().await.into()
    } else {
      RepeatedSortPB { items: vec![] }
    }
  }

  pub async fn delete_all_sorts(&self, view_id: &str) {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      let _ = view_editor.v_delete_all_sorts().await;
    }
  }

  /// Returns a list of fields of the view.
  /// If `field_ids` is not provided, all the fields will be returned in the order of the field that
  /// defined in the view. Otherwise, the fields will be returned in the order of the `field_ids`.
  pub fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Vec<Field> {
    let database = self.database.lock();
    let field_ids = field_ids.unwrap_or_else(|| {
      database
        .fields
        .get_all_field_orders()
        .into_iter()
        .map(|field| field.id)
        .collect()
    });
    database.get_fields(view_id, Some(field_ids))
  }

  pub async fn update_field(&self, params: FieldChangesetParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .fields
      .update_field(&params.field_id, |update| {
        update
          .set_name_if_not_none(params.name)
          .set_width_at_if_not_none(params.width.map(|value| value as i64))
          .set_visibility_if_not_none(params.visibility);
      });
    self
      .notify_did_update_database_field(&params.field_id)
      .await?;
    Ok(())
  }

  pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
    let is_primary = self
      .database
      .lock()
      .fields
      .get_field(field_id)
      .map(|field| field.is_primary)
      .unwrap_or(false);

    if is_primary {
      return Err(FlowyError::new(
        ErrorCode::Internal,
        "Can not delete primary field",
      ));
    }

    let database_id = {
      let database = self.database.lock();
      database.delete_field(field_id);
      database.get_database_id()
    };
    let notified_changeset =
      DatabaseFieldChangesetPB::delete(&database_id, vec![FieldIdPB::from(field_id)]);
    self.notify_did_update_database(notified_changeset).await?;
    Ok(())
  }

  pub async fn update_field_type_option(
    &self,
    view_id: &str,
    field_id: &str,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> FlowyResult<()> {
    let field_type = FieldType::from(old_field.field_type);
    self
      .database
      .lock()
      .fields
      .update_field(field_id, |update| {
        if old_field.is_primary {
          tracing::warn!("Cannot update primary field type");
        } else {
          update.update_type_options(|type_options_update| {
            type_options_update.insert(&field_type.to_string(), type_option_data);
          });
        }
      });

    self
      .database_views
      .did_update_field_type_option(view_id, field_id, &old_field)
      .await?;
    let _ = self.notify_did_update_database_field(field_id).await;
    Ok(())
  }

  pub async fn switch_to_field_type(
    &self,
    field_id: &str,
    new_field_type: &FieldType,
  ) -> FlowyResult<()> {
    let field = self.database.lock().fields.get_field(field_id);
    match field {
      None => {},
      Some(field) => {
        if field.is_primary {
          return Err(FlowyError::new(
            ErrorCode::Internal,
            "Can not update primary field's field type",
          ));
        }

        let old_field_type = FieldType::from(field.field_type);
        let old_type_option = field.get_any_type_option(old_field_type.clone());
        let new_type_option = field
          .get_any_type_option(new_field_type)
          .unwrap_or_else(|| default_type_option_data_from_type(new_field_type));

        let transformed_type_option = transform_type_option(
          &new_type_option,
          new_field_type,
          old_type_option,
          old_field_type,
        );
        self
          .database
          .lock()
          .fields
          .update_field(field_id, |update| {
            update
              .set_field_type(new_field_type.into())
              .set_type_option(new_field_type.into(), Some(transformed_type_option));
          });
      },
    }

    self.notify_did_update_database_field(field_id).await?;
    Ok(())
  }

  pub async fn duplicate_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let is_primary = self
      .database
      .lock()
      .fields
      .get_field(field_id)
      .map(|field| field.is_primary)
      .unwrap_or(false);

    if is_primary {
      return Err(FlowyError::new(
        ErrorCode::Internal,
        "Can not duplicate primary field",
      ));
    }

    let value = self
      .database
      .lock()
      .duplicate_field(view_id, field_id, |field| format!("{} (copy)", field.name));
    if let Some((index, duplicated_field)) = value {
      let _ = self
        .notify_did_insert_database_field(duplicated_field, index)
        .await;
    }
    Ok(())
  }

  // consider returning a result. But most of the time, it should be fine to just ignore the error.
  pub async fn duplicate_row(&self, view_id: &str, group_id: Option<String>, row_id: &RowId) {
    let params = self.database.lock().duplicate_row(row_id);
    match params {
      None => {
        tracing::warn!("Failed to duplicate row: {}", row_id);
      },
      Some(params) => {
        let _ = self.create_row(view_id, group_id, params).await;
      },
    }
  }

  pub async fn move_row(&self, view_id: &str, from: RowId, to: RowId) {
    let database = self.database.lock();
    if let (Some(row), Some(from_index), Some(to_index)) = (
      database.get_row(&from),
      database.index_of_row(view_id, &from),
      database.index_of_row(view_id, &to),
    ) {
      database.views.update_database_view(view_id, |view| {
        view.move_row_order(from_index as u32, to_index as u32);
      });
      drop(database);

      let delete_row_id = from.into_inner();
      let insert_row = InsertedRowPB::from(&row).with_index(to_index as i32);
      let changes =
        RowsChangePB::from_move(view_id.to_string(), vec![delete_row_id], vec![insert_row]);
      send_notification(view_id, DatabaseNotification::DidUpdateViewRows)
        .payload(changes)
        .send();
    }
  }

  pub async fn create_row(
    &self,
    view_id: &str,
    group_id: Option<String>,
    mut params: CreateRowParams,
  ) -> FlowyResult<Option<Row>> {
    for view in self.database_views.editors().await {
      view.v_will_create_row(&mut params.cells, &group_id).await;
    }
    let result = self.database.lock().create_row_in_view(view_id, params);
    if let Some((index, row_order)) = result {
      tracing::trace!("create row: {:?} at {}", row_order, index);
      let row = self.database.lock().get_row(&row_order.id);
      if let Some(row) = row {
        for view in self.database_views.editors().await {
          view.v_did_create_row(&row, &group_id, index).await;
        }
        return Ok(Some(row));
      }
    }

    Ok(None)
  }

  pub async fn get_field_type_option_data(&self, field_id: &str) -> Option<(Field, Bytes)> {
    let field = self.database.lock().fields.get_field(field_id);
    field.map(|field| {
      let field_type = FieldType::from(field.field_type);
      let type_option = field
        .get_any_type_option(field_type.clone())
        .unwrap_or_else(|| default_type_option_data_from_type(&field_type));
      (field, type_option_to_pb(type_option, &field_type))
    })
  }

  pub async fn create_field_with_type_option(
    &self,
    view_id: &str,
    field_type: &FieldType,
    type_option_data: Option<Vec<u8>>,
  ) -> (Field, Bytes) {
    let name = field_type.default_name();
    let type_option_data = match type_option_data {
      None => default_type_option_data_from_type(field_type),
      Some(type_option_data) => type_option_data_from_pb_or_default(type_option_data, field_type),
    };
    let (index, field) =
      self
        .database
        .lock()
        .create_default_field(view_id, name, field_type.into(), |field| {
          field
            .type_options
            .insert(field_type.to_string(), type_option_data.clone());
        });

    let _ = self
      .notify_did_insert_database_field(field.clone(), index)
      .await;

    (field, type_option_to_pb(type_option_data, field_type))
  }

  pub async fn move_field(
    &self,
    view_id: &str,
    field_id: &str,
    from: i32,
    to: i32,
  ) -> FlowyResult<()> {
    let (database_id, field) = {
      let database = self.database.lock();
      database.views.update_database_view(view_id, |view_update| {
        view_update.move_field_order(from as u32, to as u32);
      });
      let field = database.fields.get_field(field_id);
      let database_id = database.get_database_id();
      (database_id, field)
    };

    if let Some(field) = field {
      let delete_field = FieldIdPB::from(field_id);
      let insert_field = IndexFieldPB::from_field(field, to as usize);
      let notified_changeset = DatabaseFieldChangesetPB {
        view_id: database_id,
        inserted_fields: vec![insert_field],
        deleted_fields: vec![delete_field],
        updated_fields: vec![],
      };

      self.notify_did_update_database(notified_changeset).await?;
    }
    Ok(())
  }

  pub async fn get_rows(&self, view_id: &str) -> FlowyResult<Vec<Arc<Row>>> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    Ok(view_editor.v_get_rows().await)
  }

  pub fn get_row(&self, row_id: &RowId) -> Option<Row> {
    self.database.lock().get_row(row_id)
  }

  pub async fn delete_row(&self, row_id: &RowId) {
    let row = self.database.lock().remove_row(row_id);
    if let Some(row) = row {
      tracing::trace!("Did delete row:{:?}", row);
      for view in self.database_views.editors().await {
        view.v_did_delete_row(&row).await;
      }
    }
  }

  pub async fn get_cell(&self, field_id: &str, row_id: &RowId) -> Option<Cell> {
    let database = self.database.lock();
    let field = database.fields.get_field(field_id)?;
    let field_type = FieldType::from(field.field_type);
    // If the cell data is referenced, return the reference data. Otherwise, return an empty cell.
    match field_type {
      FieldType::LastEditedTime | FieldType::CreatedTime => database
        .get_row(row_id)
        .map(|row| {
          if field_type.is_created_time() {
            DateCellData::new(row.created_at, true)
          } else {
            DateCellData::new(row.modified_at, true)
          }
        })
        .map(Cell::from),
      _ => database.get_cell(field_id, row_id).cell,
    }
  }

  pub async fn get_cell_pb(&self, field_id: &str, row_id: &RowId) -> Option<CellPB> {
    let (field, cell) = {
      let database = self.database.lock();
      let field = database.fields.get_field(field_id)?;
      let field_type = FieldType::from(field.field_type);
      // If the cell data is referenced, return the reference data. Otherwise, return an empty cell.
      let cell = match field_type {
        FieldType::LastEditedTime | FieldType::CreatedTime => database
          .get_row(row_id)
          .map(|row| {
            if field_type.is_created_time() {
              DateCellData::new(row.created_at, true)
            } else {
              DateCellData::new(row.modified_at, true)
            }
          })
          .map(Cell::from),
        _ => database.get_cell(field_id, row_id).cell,
      }?;

      (field, cell)
    };

    let field_type = FieldType::from(field.field_type);
    let cell_bytes = get_cell_protobuf(&cell, &field, Some(self.cell_cache.clone()));
    Some(CellPB {
      field_id: field_id.to_string(),
      row_id: row_id.clone().into(),
      data: cell_bytes.to_vec(),
      field_type: Some(field_type),
    })
  }

  pub async fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Vec<RowCell> {
    let database = self.database.lock();
    if let Some(field) = database.fields.get_field(field_id) {
      let field_type = FieldType::from(field.field_type);
      match field_type {
        FieldType::LastEditedTime | FieldType::CreatedTime => database
          .get_rows_for_view(view_id)
          .into_iter()
          .map(|row| {
            let data = if field_type.is_created_time() {
              DateCellData::new(row.created_at, true)
            } else {
              DateCellData::new(row.modified_at, true)
            };
            RowCell {
              row_id: row.id,
              cell: Some(Cell::from(data)),
            }
          })
          .collect(),
        _ => database.get_cells_for_field(view_id, field_id),
      }
    } else {
      vec![]
    }
  }

  pub async fn update_cell_with_changeset<T>(
    &self,
    view_id: &str,
    row_id: RowId,
    field_id: &str,
    cell_changeset: T,
  ) -> FlowyResult<()>
  where
    T: ToCellChangeset,
  {
    let (field, cell) = {
      let database = self.database.lock();
      let field = match database.fields.get_field(field_id) {
        Some(field) => Ok(field),
        None => {
          let msg = format!("Field with id:{} not found", &field_id);
          Err(FlowyError::internal().context(msg))
        },
      }?;
      (field, database.get_cell(field_id, &row_id).cell)
    };
    let new_cell =
      apply_cell_changeset(cell_changeset, cell, &field, Some(self.cell_cache.clone()))?;
    self.update_cell(view_id, row_id, field_id, new_cell).await
  }

  /// Update a cell in the database.
  /// This will notify all views that the cell has been updated.
  pub async fn update_cell(
    &self,
    view_id: &str,
    row_id: RowId,
    field_id: &str,
    new_cell: Cell,
  ) -> FlowyResult<()> {
    // Get the old row before updating the cell. It would be better to get the old cell
    let old_row = { self.database.lock().get_row(&row_id) };

    // Get all auto updated fields. It will be used to notify the frontend
    // that the fields have been updated.
    let auto_updated_fields = self.get_auto_updated_fields(view_id);

    self.database.lock().update_row(&row_id, |row_update| {
      row_update.update_cells(|cell_update| {
        cell_update.insert(field_id, new_cell);
      });
    });

    let option_row = self.database.lock().get_row(&row_id);
    if let Some(new_row) = option_row {
      let updated_row = UpdatedRowPB {
        row: RowPB::from(&new_row),
        field_ids: vec![field_id.to_string()],
      };
      let changes = RowsChangePB::from_update(view_id.to_string(), updated_row);
      send_notification(view_id, DatabaseNotification::DidUpdateViewRows)
        .payload(changes)
        .send();

      for view in self.database_views.editors().await {
        view.v_did_update_row(&old_row, &new_row, field_id).await;
      }
    }

    // Collect all the updated field's id. Notify the frontend that all of them have been updated.
    let mut auto_updated_field_ids = auto_updated_fields
      .into_iter()
      .map(|field| field.id)
      .collect::<Vec<String>>();
    auto_updated_field_ids.push(field_id.to_string());
    let changeset = auto_updated_field_ids
      .into_iter()
      .map(|field_id| CellChangesetNotifyPB {
        view_id: view_id.to_string(),
        row_id: row_id.clone().into_inner(),
        field_id,
      })
      .collect();
    notify_did_update_cell(changeset).await;

    Ok(())
  }

  /// Just create an option for the field's type option. The option is save to the database.
  pub async fn create_select_option(
    &self,
    field_id: &str,
    option_name: String,
  ) -> Option<SelectOptionPB> {
    let field = self.database.lock().fields.get_field(field_id)?;
    let type_option = select_type_option_from_field(&field).ok()?;
    let select_option = type_option.create_option(&option_name);
    Some(SelectOptionPB::from(select_option))
  }

  /// Insert the options into the field's type option and update the cell content with the new options.
  /// Only used for single select and multiple select.
  pub async fn insert_select_options(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: RowId,
    options: Vec<SelectOptionPB>,
  ) -> FlowyResult<()> {
    let field = self
      .database
      .lock()
      .fields
      .get_field(field_id)
      .ok_or_else(|| {
        FlowyError::record_not_found().context(format!("Field with id:{} not found", &field_id))
      })?;
    debug_assert!(FieldType::from(field.field_type).is_select_option());

    let mut type_option = select_type_option_from_field(&field)?;
    let cell_changeset = SelectOptionCellChangeset {
      insert_option_ids: options.iter().map(|option| option.id.clone()).collect(),
      ..Default::default()
    };
    options
      .into_iter()
      .for_each(|option| type_option.insert_option(option.into()));

    // Update the field's type option
    self
      .update_field_type_option(view_id, field_id, type_option.to_type_option_data(), field)
      .await?;
    // Insert the options into the cell
    self
      .update_cell_with_changeset(view_id, row_id, field_id, cell_changeset)
      .await?;
    Ok(())
  }

  pub async fn delete_select_options(
    &self,
    view_id: &str,
    field_id: &str,
    row_id: RowId,
    options: Vec<SelectOptionPB>,
  ) -> FlowyResult<()> {
    let field = match self.database.lock().fields.get_field(field_id) {
      Some(field) => Ok(field),
      None => {
        let msg = format!("Field with id:{} not found", &field_id);
        Err(FlowyError::internal().context(msg))
      },
    }?;
    let mut type_option = select_type_option_from_field(&field)?;
    let cell_changeset = SelectOptionCellChangeset {
      delete_option_ids: options.iter().map(|option| option.id.clone()).collect(),
      ..Default::default()
    };

    for option in options {
      type_option.delete_option(option.into());
    }
    self
      .database
      .lock()
      .fields
      .update_field(field_id, |update| {
        update.set_type_option(field.field_type, Some(type_option.to_type_option_data()));
      });

    self
      .update_cell_with_changeset(view_id, row_id, field_id, cell_changeset)
      .await?;
    Ok(())
  }

  pub async fn get_select_options(&self, row_id: RowId, field_id: &str) -> SelectOptionCellDataPB {
    let field = self.database.lock().fields.get_field(field_id);
    match field {
      None => SelectOptionCellDataPB::default(),
      Some(field) => {
        let cell = self.database.lock().get_cell(field_id, &row_id).cell;
        let ids = match cell {
          None => SelectOptionIds::new(),
          Some(cell) => SelectOptionIds::from(&cell),
        };
        match select_type_option_from_field(&field) {
          Ok(type_option) => type_option.get_selected_options(ids).into(),
          Err(_) => SelectOptionCellDataPB::default(),
        }
      },
    }
  }

  pub async fn get_checklist_option(&self, row_id: RowId, field_id: &str) -> ChecklistCellDataPB {
    let row_cell = self.database.lock().get_cell(field_id, &row_id);
    let cell_data = match row_cell.cell {
      None => ChecklistCellData::default(),
      Some(cell) => ChecklistCellData::from(&cell),
    };
    ChecklistCellDataPB::from(cell_data)
  }

  pub async fn set_checklist_options(
    &self,
    view_id: &str,
    row_id: RowId,
    field_id: &str,
    changeset: ChecklistCellChangeset,
  ) -> FlowyResult<()> {
    let field = self
      .database
      .lock()
      .fields
      .get_field(field_id)
      .ok_or_else(|| {
        FlowyError::record_not_found().context(format!("Field with id:{} not found", &field_id))
      })?;
    debug_assert!(FieldType::from(field.field_type).is_checklist());

    self
      .update_cell_with_changeset(view_id, row_id, field_id, changeset)
      .await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn load_groups(&self, view_id: &str) -> FlowyResult<RepeatedGroupPB> {
    let view = self.database_views.get_view_editor(view_id).await?;
    let groups = view.v_load_groups().await.unwrap_or_default();
    Ok(RepeatedGroupPB { items: groups })
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn get_group(&self, view_id: &str, group_id: &str) -> FlowyResult<GroupPB> {
    let view = self.database_views.get_view_editor(view_id).await?;
    let group = view.v_get_group(group_id).await?;
    Ok(group)
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn move_group(
    &self,
    view_id: &str,
    from_group: &str,
    to_group: &str,
  ) -> FlowyResult<()> {
    let view = self.database_views.get_view_editor(view_id).await?;
    view.v_move_group(from_group, to_group).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn move_group_row(
    &self,
    view_id: &str,
    to_group: &str,
    from_row: RowId,
    to_row: Option<RowId>,
  ) -> FlowyResult<()> {
    let row = self.database.lock().get_row(&from_row);
    match row {
      None => {
        tracing::warn!(
          "Move row between group failed, can not find the row:{}",
          from_row
        )
      },
      Some(row) => {
        let mut row_changeset = RowChangeset::new(row.id.clone());
        let view = self.database_views.get_view_editor(view_id).await?;
        view
          .v_move_group_row(&row, &mut row_changeset, to_group, to_row)
          .await;

        tracing::trace!("Row data changed: {:?}", row_changeset);
        self.database.lock().update_row(&row.id, |row| {
          row.set_cells(Cells::from(row_changeset.cell_by_field_id.clone()));
        });

        let cell_changesets = cell_changesets_from_cell_by_field_id(
          view_id,
          row_changeset.row_id,
          row_changeset.cell_by_field_id,
        );
        notify_did_update_cell(cell_changesets).await;
      },
    }

    Ok(())
  }

  pub async fn group_by_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let view = self.database_views.get_view_editor(view_id).await?;
    view.v_update_grouping_field(field_id).await?;
    Ok(())
  }

  pub async fn set_layout_setting(&self, view_id: &str, layout_setting: LayoutSettingParams) {
    if let Ok(view) = self.database_views.get_view_editor(view_id).await {
      let _ = view.v_set_layout_settings(layout_setting).await;
    }
  }

  pub async fn get_layout_setting(
    &self,
    view_id: &str,
    layout_ty: DatabaseLayout,
  ) -> Option<LayoutSettingParams> {
    let view = self.database_views.get_view_editor(view_id).await.ok()?;
    let layout_setting = view.v_get_layout_settings(&layout_ty).await;
    Some(layout_setting)
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn get_all_calendar_events(&self, view_id: &str) -> Vec<CalendarEventPB> {
    match self.database_views.get_view_editor(view_id).await {
      Ok(view) => view.v_get_all_calendar_events().await.unwrap_or_default(),
      Err(_) => {
        tracing::warn!("Can not find the view: {}", view_id);
        vec![]
      },
    }
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn get_all_no_date_calendar_events(
    &self,
    view_id: &str,
  ) -> FlowyResult<Vec<NoDateCalendarEventPB>> {
    let _database_view = self.database_views.get_view_editor(view_id).await?;
    todo!()
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn get_calendar_event(&self, view_id: &str, row_id: RowId) -> Option<CalendarEventPB> {
    let view = self.database_views.get_view_editor(view_id).await.ok()?;
    view.v_get_calendar_event(row_id).await
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  async fn notify_did_insert_database_field(&self, field: Field, index: usize) -> FlowyResult<()> {
    let database_id = self.database.lock().get_database_id();
    let index_field = IndexFieldPB::from_field(field, index);
    let notified_changeset = DatabaseFieldChangesetPB::insert(&database_id, vec![index_field]);
    let _ = self.notify_did_update_database(notified_changeset).await;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  async fn notify_did_update_database_field(&self, field_id: &str) -> FlowyResult<()> {
    let (database_id, field) = {
      let database = self.database.lock();
      let database_id = database.get_database_id();
      let field = database.fields.get_field(field_id);
      (database_id, field)
    };

    if let Some(field) = field {
      let updated_field = FieldPB::from(field);
      let notified_changeset =
        DatabaseFieldChangesetPB::update(&database_id, vec![updated_field.clone()]);
      self.notify_did_update_database(notified_changeset).await?;
      send_notification(field_id, DatabaseNotification::DidUpdateField)
        .payload(updated_field)
        .send();
    }

    Ok(())
  }

  async fn notify_did_update_database(
    &self,
    changeset: DatabaseFieldChangesetPB,
  ) -> FlowyResult<()> {
    let views = self.database.lock().get_all_views_description();
    for view in views {
      send_notification(&view.id, DatabaseNotification::DidUpdateFields)
        .payload(changeset.clone())
        .send();
    }

    Ok(())
  }

  pub async fn get_database_view_setting(
    &self,
    view_id: &str,
  ) -> FlowyResult<DatabaseViewSettingPB> {
    let view = self
      .database
      .lock()
      .get_view(view_id)
      .ok_or_else(|| FlowyError::record_not_found().context("Can't find the database view"))?;
    Ok(database_view_setting_pb_from_view(view))
  }

  pub async fn get_database_data(&self, view_id: &str) -> FlowyResult<DatabasePB> {
    let database_view = self.database_views.get_view_editor(view_id).await?;
    let view = database_view
      .get_view()
      .await
      .ok_or_else(FlowyError::record_not_found)?;
    let rows = database_view.v_get_rows().await;
    let (database_id, fields) = {
      let database = self.database.lock();
      let database_id = database.get_database_id();
      let fields = database
        .fields
        .get_all_field_orders()
        .into_iter()
        .map(FieldIdPB::from)
        .collect();
      (database_id, fields)
    };

    let rows = rows
      .into_iter()
      .map(|row| RowPB::from(row.as_ref()))
      .collect::<Vec<RowPB>>();
    Ok(DatabasePB {
      id: database_id,
      fields,
      rows,
      layout_type: view.layout.into(),
    })
  }

  pub async fn export_csv(&self, style: CSVFormat) -> FlowyResult<String> {
    let database = self.database.clone();
    let csv = tokio::task::spawn_blocking(move || {
      let database_guard = database.lock();
      let csv = CSVExport.export_database(&database_guard, style)?;
      Ok::<String, FlowyError>(csv)
    })
    .await
    .map_err(internal_error)??;
    Ok(csv)
  }

  fn get_auto_updated_fields(&self, view_id: &str) -> Vec<Field> {
    self
      .database
      .lock()
      .get_fields(view_id, None)
      .into_iter()
      .filter(|f| FieldType::from(f.field_type).is_auto_update())
      .collect::<Vec<Field>>()
  }
}

pub(crate) async fn notify_did_update_cell(changesets: Vec<CellChangesetNotifyPB>) {
  for changeset in changesets {
    let id = format!("{}:{}", changeset.row_id, changeset.field_id);
    send_notification(&id, DatabaseNotification::DidUpdateCell).send();
  }
}

fn cell_changesets_from_cell_by_field_id(
  view_id: &str,
  row_id: RowId,
  cell_by_field_id: HashMap<String, Cell>,
) -> Vec<CellChangesetNotifyPB> {
  let row_id = row_id.into_inner();
  cell_by_field_id
    .into_iter()
    .map(|(field_id, _cell)| CellChangesetNotifyPB {
      view_id: view_id.to_string(),
      row_id: row_id.clone(),
      field_id,
    })
    .collect()
}

#[derive(Clone)]
pub struct MutexDatabase(Arc<Mutex<Arc<InnerDatabase>>>);

impl MutexDatabase {
  pub(crate) fn new(database: Arc<InnerDatabase>) -> Self {
    Self(Arc::new(Mutex::new(database)))
  }
}

impl Deref for MutexDatabase {
  type Target = Arc<Mutex<Arc<InnerDatabase>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

unsafe impl Sync for MutexDatabase {}

unsafe impl Send for MutexDatabase {}

struct DatabaseViewDataImpl {
  database: MutexDatabase,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  cell_cache: CellCache,
}

impl DatabaseViewData for DatabaseViewDataImpl {
  fn get_view(&self, view_id: &str) -> Fut<Option<DatabaseView>> {
    let view = self.database.lock().get_view(view_id);
    to_fut(async move { view })
  }

  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>> {
    let fields = self.database.lock().get_fields(view_id, field_ids);
    to_fut(async move { fields.into_iter().map(Arc::new).collect() })
  }

  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>> {
    let field = self
      .database
      .lock()
      .fields
      .get_field(field_id)
      .map(Arc::new);
    to_fut(async move { field })
  }

  fn create_field(
    &self,
    view_id: &str,
    name: &str,
    field_type: FieldType,
    type_option_data: TypeOptionData,
  ) -> Fut<Field> {
    let (_, field) = self.database.lock().create_default_field(
      view_id,
      name.to_string(),
      field_type.clone().into(),
      |field| {
        field
          .type_options
          .insert(field_type.to_string(), type_option_data);
      },
    );
    to_fut(async move { field })
  }

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>> {
    let field = self
      .database
      .lock()
      .fields
      .get_primary_field()
      .map(Arc::new);
    to_fut(async move { field })
  }

  fn index_of_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<usize>> {
    let index = self.database.lock().index_of_row(view_id, row_id);
    to_fut(async move { index })
  }

  fn get_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<(usize, Arc<Row>)>> {
    let index = self.database.lock().index_of_row(view_id, row_id);
    let row = self.database.lock().get_row(row_id);
    to_fut(async move {
      match (index, row) {
        (Some(index), Some(row)) => Some((index, Arc::new(row))),
        _ => None,
      }
    })
  }

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>> {
    let rows = self.database.lock().get_rows_for_view(view_id);
    to_fut(async move { rows.into_iter().map(Arc::new).collect() })
  }

  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>> {
    let cells = self.database.lock().get_cells_for_field(view_id, field_id);
    to_fut(async move { cells.into_iter().map(Arc::new).collect() })
  }

  fn get_cell_in_row(&self, field_id: &str, row_id: &RowId) -> Fut<Arc<RowCell>> {
    let cell = self.database.lock().get_cell(field_id, row_id);
    to_fut(async move { Arc::new(cell) })
  }

  fn get_layout_for_view(&self, view_id: &str) -> DatabaseLayout {
    self.database.lock().views.get_database_view_layout(view_id)
  }

  fn get_group_setting(&self, view_id: &str) -> Vec<GroupSetting> {
    self.database.lock().get_all_group_setting(view_id)
  }

  fn insert_group_setting(&self, view_id: &str, setting: GroupSetting) {
    self.database.lock().insert_group_setting(view_id, setting);
  }

  fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Sort> {
    self.database.lock().get_sort::<Sort>(view_id, sort_id)
  }

  fn insert_sort(&self, view_id: &str, sort: Sort) {
    self.database.lock().insert_sort(view_id, sort);
  }

  fn remove_sort(&self, view_id: &str, sort_id: &str) {
    self.database.lock().remove_sort(view_id, sort_id);
  }

  fn get_all_sorts(&self, view_id: &str) -> Vec<Sort> {
    self.database.lock().get_all_sorts::<Sort>(view_id)
  }

  fn remove_all_sorts(&self, view_id: &str) {
    self.database.lock().remove_all_sorts(view_id);
  }

  fn get_all_filters(&self, view_id: &str) -> Vec<Arc<Filter>> {
    self
      .database
      .lock()
      .get_all_filters(view_id)
      .into_iter()
      .map(Arc::new)
      .collect()
  }

  fn delete_filter(&self, view_id: &str, filter_id: &str) {
    self.database.lock().remove_filter(view_id, filter_id);
  }

  fn insert_filter(&self, view_id: &str, filter: Filter) {
    self.database.lock().insert_filter(view_id, filter);
  }

  fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter> {
    self
      .database
      .lock()
      .get_filter::<Filter>(view_id, filter_id)
  }

  fn get_filter_by_field_id(&self, view_id: &str, field_id: &str) -> Option<Filter> {
    self
      .database
      .lock()
      .get_filter_by_field_id::<Filter>(view_id, field_id)
  }

  fn get_layout_setting(&self, view_id: &str, layout_ty: &DatabaseLayout) -> Option<LayoutSetting> {
    self.database.lock().get_layout_setting(view_id, layout_ty)
  }

  fn insert_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &DatabaseLayout,
    layout_setting: LayoutSetting,
  ) {
    self
      .database
      .lock()
      .insert_layout_setting(view_id, layout_ty, layout_setting);
  }

  fn get_layout_type(&self, view_id: &str) -> DatabaseLayout {
    self.database.lock().views.get_database_view_layout(view_id)
  }

  fn update_layout_type(&self, view_id: &str, layout_type: &DatabaseLayout) {
    self
      .database
      .lock()
      .update_layout_type(view_id, layout_type);
  }

  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>> {
    self.task_scheduler.clone()
  }

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
    TypeOptionCellExt::new_with_cell_data_cache(field, Some(self.cell_cache.clone()))
      .get_type_option_cell_data_handler(field_type)
  }
}
