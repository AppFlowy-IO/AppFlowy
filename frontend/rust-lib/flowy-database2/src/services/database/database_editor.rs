use std::collections::HashMap;
use std::sync::Arc;

use bytes::Bytes;
use collab_database::database::MutexDatabase;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, Cells, CreateRowParams, Row, RowCell, RowDetail, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting, OrderObjectPosition};
use futures::StreamExt;
use tokio::sync::{broadcast, RwLock};
use tracing::{event, warn};

use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_dispatch::prelude::af_spawn;
use lib_infra::future::{to_fut, Fut, FutureResult};

use crate::entities::*;
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::{
  apply_cell_changeset, get_cell_protobuf, AnyTypeCache, CellCache, ToCellChangeset,
};
use crate::services::database::util::database_view_setting_pb_from_view;
use crate::services::database::UpdatedRow;
use crate::services::database_view::{
  DatabaseViewChanged, DatabaseViewEditor, DatabaseViewOperation, DatabaseViews, EditorByViewId,
};
use crate::services::field::checklist_type_option::ChecklistCellChangeset;
use crate::services::field::{
  default_type_option_data_from_type, select_type_option_from_field, transform_type_option,
  type_option_data_from_pb_or_default, type_option_to_pb, SelectOptionCellChangeset,
  SelectOptionIds, TimestampCellData, TypeOptionCellDataHandler, TypeOptionCellExt,
};
use crate::services::field_settings::{
  default_field_settings_by_layout_map, FieldSettings, FieldSettingsChangesetParams,
};
use crate::services::filter::Filter;
use crate::services::group::{default_group_setting, GroupChangesets, GroupSetting, RowChangeset};
use crate::services::share::csv::{CSVExport, CSVFormat};
use crate::services::sort::Sort;

#[derive(Clone)]
pub struct DatabaseEditor {
  database: Arc<MutexDatabase>,
  pub cell_cache: CellCache,
  database_views: Arc<DatabaseViews>,
}

impl DatabaseEditor {
  pub async fn new(
    database: Arc<MutexDatabase>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Self> {
    let cell_cache = AnyTypeCache::<u64>::new();
    let database_id = database.lock().get_database_id();

    // Receive database sync state and send to frontend via the notification
    let mut sync_state = database.lock().subscribe_sync_state();
    let cloned_database_id = database_id.clone();
    af_spawn(async move {
      while let Some(sync_state) = sync_state.next().await {
        send_notification(
          &cloned_database_id,
          DatabaseNotification::DidUpdateDatabaseSyncUpdate,
        )
        .payload(DatabaseSyncStatePB::from(sync_state))
        .send();
      }
    });

    // Receive database snapshot state and send to frontend via the notification
    let mut snapshot_state = database.lock().subscribe_snapshot_state();
    af_spawn(async move {
      while let Some(snapshot_state) = snapshot_state.next().await {
        if let Some(new_snapshot_id) = snapshot_state.snapshot_id() {
          tracing::debug!(
            "Did create {} database remote snapshot: {}",
            database_id,
            new_snapshot_id
          );
          send_notification(
            &database_id,
            DatabaseNotification::DidUpdateDatabaseSnapshotState,
          )
          .payload(DatabaseSnapshotStatePB { new_snapshot_id })
          .send();
        }
      }
    });

    // Used to cache the view of the database for fast access.
    let editor_by_view_id = Arc::new(RwLock::new(EditorByViewId::default()));
    let view_operation = Arc::new(DatabaseViewOperationImpl {
      database: database.clone(),
      task_scheduler: task_scheduler.clone(),
      cell_cache: cell_cache.clone(),
      editor_by_view_id: editor_by_view_id.clone(),
    });

    let database_views = Arc::new(
      DatabaseViews::new(
        database.clone(),
        cell_cache.clone(),
        view_operation,
        editor_by_view_id,
      )
      .await?,
    );
    Ok(Self {
      database,
      cell_cache,
      database_views,
    })
  }

  /// Returns bool value indicating whether the database is empty.
  ///
  #[tracing::instrument(level = "debug", skip_all)]
  pub async fn close_view_editor(&self, view_id: &str) -> bool {
    if let Some(database) = self.database.try_lock() {
      let _ = database.flush();
    }

    self.database_views.close_view(view_id).await
  }

  pub async fn get_layout_type(&self, view_id: &str) -> DatabaseLayout {
    let view = self.database_views.get_view_editor(view_id).await.ok();
    if let Some(editor) = view {
      editor.v_get_layout_type().await
    } else {
      DatabaseLayout::default()
    }
  }

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
        database.views.update_database_view(view_id, |view| {
          view.set_groups(vec![group_setting.into()]);
        });
      }
    }

    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_initialize_new_group(field_id).await?;
    Ok(())
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    let changes = view_editor.v_delete_group(&params.group_id).await?;

    if !changes.is_empty() {
      for view in self.database_views.editors().await {
        send_notification(&view.view_id, DatabaseNotification::DidUpdateViewRows)
          .payload(changes.clone())
          .send();
      }
    }

    Ok(())
  }

  /// Returns the delete view ids.
  /// If the view is inline view, all the reference views will be deleted. So the return value
  /// will be the reference view ids and the inline view id. Otherwise, the return value will
  /// be the view id.
  pub async fn delete_database_view(&self, view_id: &str) -> FlowyResult<Vec<String>> {
    Ok(self.database.lock().delete_view(view_id))
  }

  pub async fn update_group(&self, view_id: &str, changesets: GroupChangesets) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_update_group(changesets).await?;
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
    database.get_fields_in_view(view_id, Some(field_ids))
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
    notify_did_update_database_field(&self.database, &params.field_id)?;
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

  /// Update the field type option data.
  /// Do nothing if the [TypeOptionData] is empty.
  pub async fn update_field_type_option(
    &self,
    view_id: &str,
    _field_id: &str,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    update_field_type_option_fn(&self.database, &view_editor, type_option_data, old_field).await?;

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
        let old_type_option = field.get_any_type_option(old_field_type);
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

    notify_did_update_database_field(&self.database, field_id)?;
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
        warn!("Failed to duplicate row: {}", row_id);
      },
      Some(params) => {
        let _ = self.create_row(view_id, group_id, params).await;
      },
    }
  }

  pub async fn move_row(&self, view_id: &str, from: RowId, to: RowId) {
    let database = self.database.lock();
    if let (Some(row_detail), Some(from_index), Some(to_index)) = (
      database.get_row_detail(&from),
      database.index_of_row(view_id, &from),
      database.index_of_row(view_id, &to),
    ) {
      database.views.update_database_view(view_id, |view| {
        view.move_row_order(from_index as u32, to_index as u32);
      });
      drop(database);

      let delete_row_id = from.into_inner();
      let insert_row = InsertedRowPB::new(RowMetaPB::from(row_detail)).with_index(to_index as i32);
      let changes = RowsChangePB::from_move(vec![delete_row_id], vec![insert_row]);
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
  ) -> FlowyResult<Option<RowDetail>> {
    for view in self.database_views.editors().await {
      view.v_will_create_row(&mut params.cells, &group_id).await;
    }
    let result = self.database.lock().create_row_in_view(view_id, params);
    if let Some((index, row_order)) = result {
      tracing::trace!("create row: {:?} at {}", row_order, index);
      let row_detail = self.database.lock().get_row_detail(&row_order.id);
      if let Some(row_detail) = row_detail {
        for view in self.database_views.editors().await {
          view.v_did_create_row(&row_detail, index).await;
        }
        return Ok(Some(row_detail));
      }
    }

    Ok(None)
  }

  pub async fn get_field_type_option_data(&self, field_id: &str) -> Option<(Field, Bytes)> {
    let field = self.database.lock().fields.get_field(field_id);
    field.map(|field| {
      let field_type = FieldType::from(field.field_type);
      let type_option = field
        .get_any_type_option(field_type)
        .unwrap_or_else(|| default_type_option_data_from_type(&field_type));
      (field, type_option_to_pb(type_option, &field_type))
    })
  }

  pub async fn create_field_with_type_option(&self, params: &CreateFieldParams) -> (Field, Bytes) {
    let name = params
      .field_name
      .clone()
      .unwrap_or_else(|| params.field_type.default_name());
    let type_option_data = match &params.type_option_data {
      None => default_type_option_data_from_type(&params.field_type),
      Some(type_option_data) => {
        type_option_data_from_pb_or_default(type_option_data.clone(), &params.field_type)
      },
    };
    let (index, field) = self.database.lock().create_field_with_mut(
      &params.view_id,
      name,
      params.field_type.into(),
      &params.position,
      |field| {
        field
          .type_options
          .insert(params.field_type.to_string(), type_option_data.clone());
      },
      default_field_settings_by_layout_map(),
    );

    let _ = self
      .notify_did_insert_database_field(field.clone(), index)
      .await;

    (
      field,
      type_option_to_pb(type_option_data, &params.field_type),
    )
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

  pub async fn get_rows(&self, view_id: &str) -> FlowyResult<Vec<Arc<RowDetail>>> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    Ok(view_editor.v_get_rows().await)
  }

  pub fn get_row(&self, view_id: &str, row_id: &RowId) -> Option<Row> {
    if self.database.lock().views.is_row_exist(view_id, row_id) {
      Some(self.database.lock().get_row(row_id))
    } else {
      None
    }
  }

  pub fn get_row_meta(&self, view_id: &str, row_id: &RowId) -> Option<RowMetaPB> {
    if self.database.lock().views.is_row_exist(view_id, row_id) {
      let row_meta = self.database.lock().get_row_meta(row_id)?;
      let row_document_id = self.database.lock().get_row_document_id(row_id)?;
      Some(RowMetaPB {
        id: row_id.clone().into_inner(),
        document_id: row_document_id,
        icon: row_meta.icon_url,
        cover: row_meta.cover_url,
        is_document_empty: row_meta.is_document_empty,
      })
    } else {
      warn!("the row:{} is exist in view:{}", row_id.as_str(), view_id);
      None
    }
  }

  pub fn get_row_detail(&self, view_id: &str, row_id: &RowId) -> Option<RowDetail> {
    if self.database.lock().views.is_row_exist(view_id, row_id) {
      self.database.lock().get_row_detail(row_id)
    } else {
      warn!("the row:{} is exist in view:{}", row_id.as_str(), view_id);
      None
    }
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

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn update_row_meta(&self, row_id: &RowId, changeset: UpdateRowMetaParams) {
    self.database.lock().update_row_meta(row_id, |meta_update| {
      meta_update
        .insert_cover_if_not_none(changeset.cover_url)
        .insert_icon_if_not_none(changeset.icon_url)
        .update_is_document_empty_if_not_none(changeset.is_document_empty);
    });

    // Use the temporary row meta to get rid of the lock that not implement the `Send` or 'Sync' trait.
    let row_detail = self.database.lock().get_row_detail(row_id);
    if let Some(row_detail) = row_detail {
      for view in self.database_views.editors().await {
        view.v_did_update_row_meta(row_id, &row_detail).await;
      }

      // Notifies the client that the row meta has been updated.
      send_notification(row_id.as_str(), DatabaseNotification::DidUpdateRowMeta)
        .payload(RowMetaPB::from(&row_detail))
        .send();
    }
  }

  pub async fn get_cell(&self, field_id: &str, row_id: &RowId) -> Option<Cell> {
    let database = self.database.lock();
    let field = database.fields.get_field(field_id)?;
    let field_type = FieldType::from(field.field_type);
    // If the cell data is referenced, return the reference data. Otherwise, return an empty cell.
    match field_type {
      FieldType::LastEditedTime | FieldType::CreatedTime => {
        let row = database.get_row(row_id);
        let cell_data = if field_type.is_created_time() {
          TimestampCellData::new(row.created_at)
        } else {
          TimestampCellData::new(row.modified_at)
        };
        Some(Cell::from(cell_data))
      },
      _ => database.get_cell(field_id, row_id).cell,
    }
  }

  pub async fn get_cell_pb(&self, field_id: &str, row_id: &RowId) -> Option<CellPB> {
    let (field, cell) = {
      let cell = self.get_cell(field_id, row_id).await?;
      let field = self.database.lock().fields.get_field(field_id)?;
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
              TimestampCellData::new(row.created_at)
            } else {
              TimestampCellData::new(row.modified_at)
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
          Err(FlowyError::internal().with_context(msg))
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
    let old_row = { self.get_row_detail(view_id, &row_id) };

    self.database.lock().update_row(&row_id, |row_update| {
      row_update.update_cells(|cell_update| {
        cell_update.insert(field_id, new_cell);
      });
    });

    let option_row = self.get_row_detail(view_id, &row_id);
    if let Some(new_row_detail) = option_row {
      for view in self.database_views.editors().await {
        view.v_did_update_row(&old_row, &new_row_detail).await;
      }
    }

    let changeset = CellChangesetNotifyPB {
      view_id: view_id.to_string(),
      row_id: row_id.clone().into_inner(),
      field_id: field_id.to_string(),
    };
    self
      .notify_update_row(view_id, row_id, vec![changeset])
      .await;

    Ok(())
  }

  pub fn get_auto_updated_fields_changesets(
    &self,
    view_id: &str,
    row_id: RowId,
  ) -> Vec<CellChangesetNotifyPB> {
    // Get all auto updated fields. It will be used to notify the frontend
    // that the fields have been updated.
    let auto_updated_fields = self.get_auto_updated_fields(view_id);

    // Collect all the updated field's id. Notify the frontend that all of them have been updated.
    let auto_updated_field_ids = auto_updated_fields
      .into_iter()
      .map(|field| field.id)
      .collect::<Vec<String>>();
    auto_updated_field_ids
      .into_iter()
      .map(|field_id| CellChangesetNotifyPB {
        view_id: view_id.to_string(),
        row_id: row_id.clone().into_inner(),
        field_id,
      })
      .collect()
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
        FlowyError::record_not_found()
          .with_context(format!("Field with id:{} not found", &field_id))
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
        Err(FlowyError::internal().with_context(msg))
      },
    }?;
    let mut type_option = select_type_option_from_field(&field)?;
    let cell_changeset = SelectOptionCellChangeset {
      delete_option_ids: options.iter().map(|option| option.id.clone()).collect(),
      ..Default::default()
    };

    for option in options {
      type_option.delete_option(&option.id);
    }

    notify_did_update_database_field(&self.database, field_id)?;
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
        FlowyError::record_not_found()
          .with_context(format!("Field with id:{} not found", &field_id))
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
    // Do nothing if the group is the same
    if from_group == to_group {
      return Ok(());
    }

    let view = self.database_views.get_view_editor(view_id).await?;
    view.v_move_group(from_group, to_group).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn move_group_row(
    &self,
    view_id: &str,
    from_group: &str,
    to_group: &str,
    from_row: RowId,
    to_row: Option<RowId>,
  ) -> FlowyResult<()> {
    let row_detail = self.get_row_detail(view_id, &from_row);
    match row_detail {
      None => {
        warn!(
          "Move row between group failed, can not find the row:{}",
          from_row
        )
      },
      Some(row_detail) => {
        let view = self.database_views.get_view_editor(view_id).await?;
        let mut row_changeset = RowChangeset::new(row_detail.row.id.clone());
        view
          .v_move_group_row(&row_detail, &mut row_changeset, to_group, to_row.clone())
          .await;

        let to_row = if to_row.is_some() {
          to_row
        } else {
          let row_details = self.get_rows(view_id).await?;
          row_details
            .last()
            .map(|row_detail| row_detail.row.id.clone())
        };
        if let Some(row_id) = to_row.clone() {
          self.move_row(view_id, from_row.clone(), row_id).await;
        }

        if from_group == to_group {
          return Ok(());
        }

        tracing::trace!("Row data changed: {:?}", row_changeset);
        self.database.lock().update_row(&row_detail.row.id, |row| {
          row.set_cells(Cells::from(row_changeset.cell_by_field_id.clone()));
        });

        let changesets = cell_changesets_from_cell_by_field_id(
          view_id,
          row_changeset.row_id,
          row_changeset.cell_by_field_id,
        );
        self.notify_update_row(view_id, from_row, changesets).await;
      },
    }

    Ok(())
  }

  pub async fn group_by_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let view = self.database_views.get_view_editor(view_id).await?;
    view.v_grouping_by_field(field_id).await?;
    Ok(())
  }

  pub async fn create_group(&self, view_id: &str, name: &str) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_create_group(name).await?;
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn set_layout_setting(
    &self,
    view_id: &str,
    layout_setting: LayoutSettingChangeset,
  ) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_set_layout_settings(layout_setting).await?;
    Ok(())
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
        warn!("Can not find the view: {}", view_id);
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
    Ok(vec![])
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
    let view =
      self.database.lock().get_view(view_id).ok_or_else(|| {
        FlowyError::record_not_found().with_context("Can't find the database view")
      })?;
    Ok(database_view_setting_pb_from_view(view))
  }

  pub async fn get_database_data(&self, view_id: &str) -> FlowyResult<DatabasePB> {
    let database_view = self.database_views.get_view_editor(view_id).await?;
    let view = database_view
      .v_get_view()
      .await
      .ok_or_else(FlowyError::record_not_found)?;
    let rows = database_view.v_get_rows().await;
    let (database_id, fields, is_linked) = {
      let database = self.database.lock();
      let database_id = database.get_database_id();
      let fields = database
        .fields
        .get_all_field_orders()
        .into_iter()
        .map(FieldIdPB::from)
        .collect();
      let is_linked = database.is_inline_view(view_id);
      (database_id, fields, is_linked)
    };

    let rows = rows
      .into_iter()
      .map(|row_detail| RowMetaPB::from(row_detail.as_ref()))
      .collect::<Vec<RowMetaPB>>();
    Ok(DatabasePB {
      id: database_id,
      fields,
      rows,
      layout_type: view.layout.into(),
      is_linked,
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

  pub async fn get_field_settings(
    &self,
    view_id: &str,
    field_ids: Vec<String>,
  ) -> FlowyResult<Vec<FieldSettings>> {
    let view = self.database_views.get_view_editor(view_id).await?;

    let field_settings = view
      .v_get_field_settings(&field_ids)
      .await
      .into_values()
      .collect();

    Ok(field_settings)
  }

  pub async fn get_all_field_settings(&self, view_id: &str) -> FlowyResult<Vec<FieldSettings>> {
    let field_ids = self
      .get_fields(view_id, None)
      .iter()
      .map(|field| field.id.clone())
      .collect();

    self.get_field_settings(view_id, field_ids).await
  }

  pub async fn update_field_settings_with_changeset(
    &self,
    params: FieldSettingsChangesetParams,
  ) -> FlowyResult<()> {
    let view = self.database_views.get_view_editor(&params.view_id).await?;
    view
      .v_update_field_settings(
        &params.view_id,
        &params.field_id,
        params.visibility,
        params.width,
      )
      .await?;

    Ok(())
  }

  fn get_auto_updated_fields(&self, view_id: &str) -> Vec<Field> {
    self
      .database
      .lock()
      .get_fields_in_view(view_id, None)
      .into_iter()
      .filter(|f| FieldType::from(f.field_type).is_auto_update())
      .collect::<Vec<Field>>()
  }

  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_mutex_database(&self) -> &MutexDatabase {
    &self.database
  }

  async fn notify_update_row(
    &self,
    view_id: &str,
    row: RowId,
    extra_changesets: Vec<CellChangesetNotifyPB>,
  ) {
    let mut changesets = self.get_auto_updated_fields_changesets(view_id, row);
    changesets.extend(extra_changesets);

    notify_did_update_cell(changesets.clone()).await;
    notify_did_update_row(changesets).await;
  }
}

pub(crate) async fn notify_did_update_cell(changesets: Vec<CellChangesetNotifyPB>) {
  for changeset in changesets {
    let id = format!("{}:{}", changeset.row_id, changeset.field_id);
    send_notification(&id, DatabaseNotification::DidUpdateCell).send();
  }
}

async fn notify_did_update_row(changesets: Vec<CellChangesetNotifyPB>) {
  let row_id = changesets[0].row_id.clone();
  let view_id = changesets[0].view_id.clone();

  let field_ids = changesets
    .iter()
    .map(|changeset| changeset.field_id.to_string())
    .collect();
  let update_row = UpdatedRow::new(&row_id).with_field_ids(field_ids);
  let update_changeset = RowsChangePB::from_update(update_row.into());

  send_notification(&view_id, DatabaseNotification::DidUpdateViewRows)
    .payload(update_changeset)
    .send();
}

fn cell_changesets_from_cell_by_field_id(
  view_id: &str,
  row_id: RowId,
  cell_by_field_id: HashMap<String, Cell>,
) -> Vec<CellChangesetNotifyPB> {
  let row_id = row_id.into_inner();
  cell_by_field_id
    .into_keys()
    .map(|field_id| CellChangesetNotifyPB {
      view_id: view_id.to_string(),
      row_id: row_id.clone(),
      field_id,
    })
    .collect()
}

struct DatabaseViewOperationImpl {
  database: Arc<MutexDatabase>,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  cell_cache: CellCache,
  editor_by_view_id: Arc<RwLock<EditorByViewId>>,
}

impl DatabaseViewOperation for DatabaseViewOperationImpl {
  fn get_database(&self) -> Arc<MutexDatabase> {
    self.database.clone()
  }

  fn get_view(&self, view_id: &str) -> Fut<Option<DatabaseView>> {
    let view = self.database.lock().get_view(view_id);
    to_fut(async move { view })
  }

  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>> {
    let fields = self.database.lock().get_fields_in_view(view_id, field_ids);
    to_fut(async move { fields.into_iter().map(Arc::new).collect() })
  }

  fn get_field(&self, field_id: &str) -> Option<Field> {
    self.database.lock().fields.get_field(field_id)
  }

  fn create_field(
    &self,
    view_id: &str,
    name: &str,
    field_type: FieldType,
    type_option_data: TypeOptionData,
  ) -> Fut<Field> {
    let (_, field) = self.database.lock().create_field_with_mut(
      view_id,
      name.to_string(),
      field_type.into(),
      &OrderObjectPosition::default(),
      |field| {
        field
          .type_options
          .insert(field_type.to_string(), type_option_data);
      },
      default_field_settings_by_layout_map(),
    );
    to_fut(async move { field })
  }

  fn update_field(
    &self,
    view_id: &str,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> FutureResult<(), FlowyError> {
    let view_id = view_id.to_string();
    let weak_editor_by_view_id = Arc::downgrade(&self.editor_by_view_id);
    let weak_database = Arc::downgrade(&self.database);
    FutureResult::new(async move {
      if let (Some(database), Some(editor_by_view_id)) =
        (weak_database.upgrade(), weak_editor_by_view_id.upgrade())
      {
        let view_editor = editor_by_view_id.read().await.get(&view_id).cloned();
        if let Some(view_editor) = view_editor {
          let _ =
            update_field_type_option_fn(&database, &view_editor, type_option_data, old_field).await;
        }
      }
      Ok(())
    })
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

  fn get_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<(usize, Arc<RowDetail>)>> {
    let index = self.database.lock().index_of_row(view_id, row_id);
    let row_detail = self.database.lock().get_row_detail(row_id);
    to_fut(async move {
      match (index, row_detail) {
        (Some(index), Some(row_detail)) => Some((index, Arc::new(row_detail))),
        _ => None,
      }
    })
  }

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<RowDetail>>> {
    let database = self.database.clone();
    let view_id = view_id.to_string();
    to_fut(async move {
      let cloned_database = database.clone();
      // offloads the blocking operation to a thread where blocking is acceptable. This prevents
      // blocking the main asynchronous runtime
      let row_orders = tokio::task::spawn_blocking(move || {
        cloned_database.lock().get_row_orders_for_view(&view_id)
      })
      .await
      .unwrap_or_default();
      tokio::task::yield_now().await;

      let mut all_rows = vec![];

      // Loading the rows in chunks of 10 rows in order to prevent blocking the main asynchronous runtime
      for chunk in row_orders.chunks(10) {
        let cloned_database = database.clone();
        let chunk = chunk.to_vec();
        let rows = tokio::task::spawn_blocking(move || {
          let orders = cloned_database.lock().get_rows_from_row_orders(&chunk);
          let lock_guard = cloned_database.lock();
          orders
            .into_iter()
            .flat_map(|row| lock_guard.get_row_detail(&row.id))
            .collect::<Vec<RowDetail>>()
        })
        .await
        .unwrap_or_default();

        all_rows.extend(rows);
        tokio::task::yield_now().await;
      }

      all_rows.into_iter().map(Arc::new).collect()
    })
  }

  fn remove_row(&self, row_id: &RowId) -> Option<Row> {
    self.database.lock().remove_row(row_id)
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

  fn get_field_settings(
    &self,
    view_id: &str,
    field_ids: &[String],
  ) -> HashMap<String, FieldSettings> {
    let (layout_type, field_settings_map) = {
      let database = self.database.lock();
      let layout_type = database.views.get_database_view_layout(view_id);
      let field_settings_map = database.get_field_settings(view_id, Some(field_ids));
      (layout_type, field_settings_map)
    };

    let default_field_settings = default_field_settings_by_layout_map()
      .get(&layout_type)
      .unwrap()
      .to_owned();

    let field_settings = field_ids
      .iter()
      .map(|field_id| {
        if !field_settings_map.contains_key(field_id) {
          let field_settings =
            FieldSettings::from_any_map(field_id, layout_type, &default_field_settings);
          (field_id.clone(), field_settings)
        } else {
          let field_settings = FieldSettings::from_any_map(
            field_id,
            layout_type,
            field_settings_map.get(field_id).unwrap(),
          );
          (field_id.clone(), field_settings)
        }
      })
      .collect();

    field_settings
  }

  fn update_field_settings(
    &self,
    view_id: &str,
    field_id: &str,
    visibility: Option<FieldVisibility>,
    width: Option<i32>,
  ) {
    let field_settings_map = self.get_field_settings(view_id, &[field_id.to_string()]);

    let new_field_settings = if let Some(field_settings) = field_settings_map.get(field_id) {
      FieldSettings {
        field_id: field_settings.field_id.clone(),
        visibility: visibility.unwrap_or(field_settings.visibility.clone()),
        width: width.unwrap_or(field_settings.width),
      }
    } else {
      let layout_type = self.get_layout_for_view(view_id);
      let default_field_settings = default_field_settings_by_layout_map()
        .get(&layout_type)
        .unwrap()
        .to_owned();
      let field_settings =
        FieldSettings::from_any_map(field_id, layout_type, &default_field_settings);
      FieldSettings {
        field_id: field_settings.field_id.clone(),
        visibility: visibility.unwrap_or(field_settings.visibility),
        width: width.unwrap_or(field_settings.width),
      }
    };

    self.database.lock().update_field_settings(
      view_id,
      Some(vec![field_id.to_string()]),
      new_field_settings.clone(),
    );

    send_notification(view_id, DatabaseNotification::DidUpdateFieldSettings)
      .payload(FieldSettingsPB::from(new_field_settings))
      .send()
  }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub async fn update_field_type_option_fn(
  database: &Arc<MutexDatabase>,
  view_editor: &Arc<DatabaseViewEditor>,
  type_option_data: TypeOptionData,
  old_field: Field,
) -> FlowyResult<()> {
  if type_option_data.is_empty() {
    warn!("Update type option with empty data");
    return Ok(());
  }
  let field_type = FieldType::from(old_field.field_type);
  database
    .lock()
    .fields
    .update_field(&old_field.id, |update| {
      if old_field.is_primary {
        warn!("Cannot update primary field type");
      } else {
        update.update_type_options(|type_options_update| {
          event!(
            tracing::Level::TRACE,
            "insert type option to field type: {:?}",
            field_type
          );
          type_options_update.insert(&field_type.to_string(), type_option_data);
        });
      }
    });

  let _ = notify_did_update_database_field(database, &old_field.id);
  view_editor
    .v_did_update_field_type_option(&old_field)
    .await?;
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
fn notify_did_update_database_field(
  database: &Arc<MutexDatabase>,
  field_id: &str,
) -> FlowyResult<()> {
  let (database_id, field, views) = {
    let database = database
      .try_lock()
      .ok_or(FlowyError::internal().with_context("fail to acquire the lock of database"))?;
    let database_id = database.get_database_id();
    let field = database.fields.get_field(field_id);
    let views = database.get_all_views_description();
    (database_id, field, views)
  };

  if let Some(field) = field {
    let updated_field = FieldPB::from(field);
    let notified_changeset =
      DatabaseFieldChangesetPB::update(&database_id, vec![updated_field.clone()]);

    for view in views {
      send_notification(&view.id, DatabaseNotification::DidUpdateFields)
        .payload(notified_changeset.clone())
        .send();
    }

    send_notification(field_id, DatabaseNotification::DidUpdateField)
      .payload(updated_field)
      .send();
  }
  Ok(())
}
