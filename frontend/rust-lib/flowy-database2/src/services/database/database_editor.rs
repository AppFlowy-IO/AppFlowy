use crate::entities::*;
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::calculations::Calculation;
use crate::services::cell::{apply_cell_changeset, get_cell_protobuf, CellCache};
use crate::services::database::database_observe::*;
use crate::services::database::util::database_view_setting_pb_from_view;
use crate::services::database_view::{
  DatabaseViewChanged, DatabaseViewOperation, DatabaseViews, EditorByViewId,
};
use crate::services::field::{
  default_type_option_data_from_type, select_type_option_from_field, transform_type_option,
  type_option_data_from_pb, ChecklistCellChangeset, RelationTypeOption, SelectOptionCellChangeset,
  StringCellData, TimestampCellData, TimestampCellDataWrapper, TypeOptionCellDataHandler,
  TypeOptionCellExt,
};
use crate::services::field_settings::{default_field_settings_by_layout_map, FieldSettings};
use crate::services::filter::{Filter, FilterChangeset};
use crate::services::group::{default_group_setting, GroupChangeset, GroupSetting, RowChangeset};
use crate::services::share::csv::{CSVExport, CSVFormat};
use crate::services::sort::Sort;
use crate::utils::cache::AnyTypeCache;
use async_trait::async_trait;
use collab_database::database::Database;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, Cells, Row, RowCell, RowDetail, RowId};
use collab_database::views::{
  DatabaseLayout, DatabaseView, FilterMap, LayoutSetting, OrderObjectPosition,
};
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_notification::DebounceNotificationSender;
use lib_infra::box_any::BoxAny;
use lib_infra::priority_task::TaskDispatcher;
use lib_infra::util::timestamp;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};
use tracing::{event, instrument, warn};

#[derive(Clone)]
pub struct DatabaseEditor {
  database: Arc<RwLock<Database>>,
  pub cell_cache: CellCache,
  database_views: Arc<DatabaseViews>,
  #[allow(dead_code)]
  /// Used to send notification to the frontend.
  notification_sender: Arc<DebounceNotificationSender>,
}

impl DatabaseEditor {
  pub async fn new(
    database: Arc<RwLock<Database>>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Self> {
    let notification_sender = Arc::new(DebounceNotificationSender::new(200));
    let cell_cache = AnyTypeCache::<u64>::new();
    let database_id = database.read().await.get_database_id();
    // Receive database sync state and send to frontend via the notification
    observe_sync_state(&database_id, &database).await;
    // observe_view_change(&database_id, &database).await;
    // observe_field_change(&database_id, &database).await;
    observe_rows_change(&database_id, &database, &notification_sender).await;
    // observe_block_event(&database_id, &database).await;

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
      notification_sender,
    })
  }

  pub async fn close_view(&self, view_id: &str) {
    self.database_views.close_view(view_id).await;
  }

  pub async fn get_row_ids(&self) -> Vec<RowId> {
    self
      .database
      .read()
      .await
      .get_database_rows()
      .into_iter()
      .map(|entry| entry.id)
      .collect()
  }

  pub async fn num_views(&self) -> usize {
    self.database_views.num_editors().await
  }

  #[tracing::instrument(level = "debug", skip_all)]
  pub async fn close_all_views(&self) {
    for view in self.database_views.editors().await {
      view.close().await;
    }
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

  pub async fn get_field(&self, field_id: &str) -> Option<Field> {
    self.database.read().await.get_field(field_id)
  }

  pub async fn set_group_by_field(
    &self,
    view_id: &str,
    field_id: &str,
    data: Vec<u8>,
  ) -> FlowyResult<()> {
    let old_group_settings: Vec<GroupSetting>;
    let mut setting_content = "".to_string();
    {
      let mut database = self.database.write().await;
      let field = database.get_field(field_id);
      old_group_settings = database.get_all_group_setting(view_id);
      if let Some(field) = field {
        let field_type = FieldType::from(field.field_type);
        setting_content = group_config_pb_to_json_str(data, &field_type)?;
        let mut group_setting = default_group_setting(&field);
        group_setting.content = setting_content.clone();
        database.update_database_view(view_id, |view| {
          view.set_groups(vec![group_setting.into()]);
        });
      }
    }

    let old_group_setting = old_group_settings.iter().find(|g| g.field_id == field_id);
    let has_same_content =
      old_group_setting.is_some() && old_group_setting.unwrap().content == setting_content;

    let view_editor = self.database_views.get_view_editor(view_id).await?;
    if !view_editor.is_grouping_field(field_id).await || !has_same_content {
      view_editor.v_initialize_new_group(field_id).await?;
    }
    Ok(())
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    let changes = view_editor.v_delete_group(&params.group_id).await?;

    if !changes.is_empty() {
      for view in self.database_views.editors().await {
        send_notification(&view.view_id, DatabaseNotification::DidUpdateRow)
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
    Ok(self.database.write().await.delete_view(view_id))
  }

  pub async fn update_group(
    &self,
    view_id: &str,
    changesets: Vec<GroupChangeset>,
  ) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_update_group(changesets).await?;
    Ok(())
  }

  pub async fn modify_view_filters(
    &self,
    view_id: &str,
    changeset: FilterChangeset,
  ) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    view_editor.v_modify_filters(changeset).await?;
    Ok(())
  }

  pub async fn create_or_update_sort(&self, params: UpdateSortPayloadPB) -> FlowyResult<Sort> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    let sort = view_editor.v_create_or_update_sort(params).await?;
    Ok(sort)
  }

  pub async fn reorder_sort(&self, params: ReorderSortPayloadPB) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_reorder_sort(params).await?;
    Ok(())
  }

  pub async fn delete_sort(&self, params: DeleteSortPayloadPB) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_sort(params).await?;
    Ok(())
  }

  pub async fn get_all_calculations(&self, view_id: &str) -> RepeatedCalculationsPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      view_editor.v_get_all_calculations().await.into()
    } else {
      RepeatedCalculationsPB { items: vec![] }
    }
  }

  pub async fn update_calculation(&self, update: UpdateCalculationChangesetPB) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&update.view_id).await?;
    view_editor.v_update_calculations(update).await?;
    Ok(())
  }

  pub async fn remove_calculation(&self, remove: RemoveCalculationChangesetPB) -> FlowyResult<()> {
    let view_editor = self.database_views.get_view_editor(&remove.view_id).await?;
    view_editor.v_remove_calculation(remove).await?;
    Ok(())
  }

  pub async fn get_all_filters(&self, view_id: &str) -> RepeatedFilterPB {
    if let Ok(view_editor) = self.database_views.get_view_editor(view_id).await {
      let filters = view_editor.v_get_all_filters().await;
      RepeatedFilterPB::from(&filters)
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
  pub async fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Vec<Field> {
    let database = self.database.read().await;
    let field_ids = field_ids.unwrap_or_else(|| {
      database
        .get_all_field_orders()
        .into_iter()
        .map(|field| field.id)
        .collect()
    });
    database.get_fields_in_view(view_id, Some(field_ids))
  }

  pub async fn update_field(&self, params: FieldChangesetParams) -> FlowyResult<()> {
    let mut database = self.database.write().await;
    database.update_field(&params.field_id, |update| {
      update.set_name_if_not_none(params.name);
    });
    notify_did_update_database_field(&database, &params.field_id)?;
    Ok(())
  }

  pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
    let is_primary = self
      .database
      .write()
      .await
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
      let mut database = self.database.write().await;
      database.delete_field(field_id);
      database.get_database_id()
    };
    let notified_changeset =
      DatabaseFieldChangesetPB::delete(&database_id, vec![FieldIdPB::from(field_id)]);
    self.notify_did_update_database(notified_changeset).await?;

    for view in self.database_views.editors().await {
      view.v_did_delete_field(field_id).await;
    }

    Ok(())
  }

  pub async fn clear_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let field_type: FieldType = self
      .get_field(field_id)
      .await
      .map(|field| field.field_type.into())
      .unwrap_or_default();

    if matches!(
      field_type,
      FieldType::LastEditedTime | FieldType::CreatedTime
    ) {
      return Err(FlowyError::new(
        ErrorCode::Internal,
        "Can not clear the field type of Last Edited Time or Created Time.",
      ));
    }

    let cells: Vec<RowCell> = self.get_cells_for_field(view_id, field_id).await;
    for row_cell in cells {
      self.clear_cell(view_id, row_cell.row_id, field_id).await?;
    }

    Ok(())
  }

  /// Update the field type option data.
  /// Do nothing if the [TypeOptionData] is empty.
  pub async fn update_field_type_option(
    &self,
    _field_id: &str,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> FlowyResult<()> {
    let view_editors = self.database_views.editors().await;
    {
      let mut database = self.database.write().await;
      update_field_type_option_fn(&mut database, type_option_data, &old_field).await?;
      drop(database);
    }

    for view_editor in view_editors {
      view_editor
        .v_did_update_field_type_option(&old_field)
        .await?;
    }
    Ok(())
  }

  pub async fn switch_to_field_type(
    &self,
    field_id: &str,
    new_field_type: FieldType,
  ) -> FlowyResult<()> {
    let mut database = self.database.write().await;
    let field = database.get_field(field_id);
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
        let old_type_option_data = field.get_any_type_option(old_field_type);
        let new_type_option_data = field
          .get_any_type_option(new_field_type)
          .unwrap_or_else(|| default_type_option_data_from_type(new_field_type));

        let transformed_type_option = transform_type_option(
          old_field_type,
          new_field_type,
          old_type_option_data,
          new_type_option_data,
        );
        database.update_field(field_id, |update| {
          update
            .set_field_type(new_field_type.into())
            .set_type_option(new_field_type.into(), Some(transformed_type_option));
        });

        for view in self.database_views.editors().await {
          view.v_did_update_field_type(field_id, new_field_type).await;
        }
      },
    }

    notify_did_update_database_field(&database, field_id)?;
    Ok(())
  }

  pub async fn duplicate_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let mut database = self.database.write().await;
    let is_primary = database
      .get_field(field_id)
      .map(|field| field.is_primary)
      .unwrap_or(false);

    if is_primary {
      return Err(FlowyError::new(
        ErrorCode::Internal,
        "Can not duplicate primary field",
      ));
    }

    let value =
      database.duplicate_field(view_id, field_id, |field| format!("{} (copy)", field.name));
    drop(database);

    if let Some((index, duplicated_field)) = value {
      let _ = self
        .notify_did_insert_database_field(duplicated_field.clone(), index)
        .await;

      let new_field_id = duplicated_field.id.clone();
      let cells = self.get_cells_for_field(view_id, field_id).await;
      for cell in cells {
        if let Some(new_cell) = cell.cell.clone() {
          self
            .update_cell(view_id, &cell.row_id, &new_field_id, new_cell)
            .await?;
        }
      }
    }
    Ok(())
  }

  pub async fn duplicate_row(&self, view_id: &str, row_id: &RowId) -> FlowyResult<()> {
    let (row_detail, index) = {
      let mut database = self.database.write().await;

      let params = database
        .duplicate_row(row_id)
        .ok_or_else(|| FlowyError::internal().with_context("error while copying row"))?;

      let (index, row_order) = database
        .create_row_in_view(view_id, params)
        .ok_or_else(|| {
          FlowyError::internal().with_context("error while inserting duplicated row")
        })?;

      tracing::trace!("duplicated row: {:?} at {}", row_order, index);
      let row_detail = database.get_row_detail(&row_order.id);

      (row_detail, index)
    };

    if let Some(row_detail) = row_detail {
      for view in self.database_views.editors().await {
        view.v_did_create_row(&row_detail, index).await;
      }
    }

    Ok(())
  }

  pub async fn move_row(
    &self,
    view_id: &str,
    from_row_id: RowId,
    to_row_id: RowId,
  ) -> FlowyResult<()> {
    let mut database = self.database.write().await;

    let row_detail = database.get_row_detail(&from_row_id).ok_or_else(|| {
      let msg = format!("Cannot find row {}", from_row_id);
      FlowyError::internal().with_context(msg)
    })?;

    database.update_database_view(view_id, |view| {
      view.move_row_order(&from_row_id, &to_row_id);
    });

    let new_index = database.index_of_row(view_id, &from_row_id);
    drop(database);

    if let Some(index) = new_index {
      let delete_row_id = from_row_id.into_inner();
      let insert_row = InsertedRowPB::new(RowMetaPB::from(row_detail)).with_index(index as i32);
      let changes = RowsChangePB::from_move(vec![delete_row_id], vec![insert_row]);

      send_notification(view_id, DatabaseNotification::DidUpdateRow)
        .payload(changes)
        .send();
    }

    Ok(())
  }

  pub async fn create_row(&self, params: CreateRowPayloadPB) -> FlowyResult<Option<RowDetail>> {
    let view_editor = self.database_views.get_view_editor(&params.view_id).await?;

    let CreateRowParams {
      collab_params,
      open_after_create: _,
    } = view_editor.v_will_create_row(params).await?;

    let mut database = self.database.write().await;
    let result = database
      .create_row_in_view(&view_editor.view_id, collab_params)
      .map(|(index, order)| {
        let row_detail = database.get_row_detail(&order.id);
        (index, row_detail)
      });
    drop(database);

    if let Some((index, row_detail)) = result {
      tracing::trace!("created row: {:?} at {}", row_detail, index);
      if let Some(row_detail) = row_detail {
        for view in self.database_views.editors().await {
          view.v_did_create_row(&row_detail, index).await;
        }
        return Ok(Some(row_detail));
      }
    }

    Ok(None)
  }

  pub async fn create_field_with_type_option(
    &self,
    params: CreateFieldParams,
  ) -> FlowyResult<FieldPB> {
    let name = params
      .field_name
      .clone()
      .unwrap_or_else(|| params.field_type.default_name());

    let type_option_data = params
      .type_option_data
      .and_then(|data| type_option_data_from_pb(data, &params.field_type).ok())
      .unwrap_or(default_type_option_data_from_type(params.field_type));

    let (index, field) = self.database.write().await.create_field_with_mut(
      &params.view_id,
      name,
      params.field_type.into(),
      &params.position,
      |field| {
        field
          .type_options
          .insert(params.field_type.to_string(), type_option_data);
      },
      default_field_settings_by_layout_map(),
    );

    let _ = self
      .notify_did_insert_database_field(field.clone(), index)
      .await;

    Ok(FieldPB::new(field))
  }

  pub async fn move_field(&self, params: MoveFieldParams) -> FlowyResult<()> {
    let (field, new_index) = {
      let mut database = self.database.write().await;

      let field = database.get_field(&params.from_field_id).ok_or_else(|| {
        let msg = format!("Field with id: {} not found", &params.from_field_id);
        FlowyError::internal().with_context(msg)
      })?;

      database.update_database_view(&params.view_id, |view_update| {
        view_update.move_field_order(&params.from_field_id, &params.to_field_id);
      });

      let new_index = database.index_of_field(&params.view_id, &params.from_field_id);

      (field, new_index)
    };

    if let Some(index) = new_index {
      let delete_field = FieldIdPB::from(params.from_field_id);
      let insert_field = IndexFieldPB {
        field: FieldPB::new(field),
        index: index as i32,
      };
      let notified_changeset = DatabaseFieldChangesetPB {
        view_id: params.view_id.clone(),
        inserted_fields: vec![insert_field],
        deleted_fields: vec![delete_field],
        updated_fields: vec![],
      };

      send_notification(&params.view_id, DatabaseNotification::DidUpdateFields)
        .payload(notified_changeset)
        .send();
    }

    Ok(())
  }

  pub async fn get_rows(&self, view_id: &str) -> FlowyResult<Vec<Arc<RowDetail>>> {
    let view_editor = self.database_views.get_view_editor(view_id).await?;
    Ok(view_editor.v_get_rows().await)
  }

  pub async fn get_row(&self, view_id: &str, row_id: &RowId) -> Option<Row> {
    let database = self.database.read().await;
    if database.contains_row(view_id, row_id) {
      Some(database.get_row(row_id))
    } else {
      None
    }
  }

  pub async fn get_row_meta(&self, view_id: &str, row_id: &RowId) -> Option<RowMetaPB> {
    let database = self.database.read().await;
    if database.contains_row(view_id, row_id) {
      let row_meta = database.get_row_meta(row_id)?;
      let row_document_id = database.get_row_document_id(row_id)?;
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

  pub async fn get_row_detail(&self, view_id: &str, row_id: &RowId) -> Option<RowDetail> {
    let database = self.database.read().await;
    if database.contains_row(view_id, row_id) {
      database.get_row_detail(row_id)
    } else {
      warn!("the row:{} is exist in view:{}", row_id.as_str(), view_id);
      None
    }
  }

  pub async fn delete_rows(&self, row_ids: &[RowId]) {
    let rows = self.database.write().await.remove_rows(row_ids);

    for row in rows {
      tracing::trace!("Did delete row:{:?}", row);
      for view in self.database_views.editors().await {
        view.v_did_delete_row(&row).await;
      }
    }
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn update_row_meta(&self, row_id: &RowId, changeset: UpdateRowMetaParams) {
    let mut database = self.database.write().await;
    database.update_row_meta(row_id, |meta_update| {
      meta_update
        .insert_cover_if_not_none(changeset.cover_url)
        .insert_icon_if_not_none(changeset.icon_url)
        .update_is_document_empty_if_not_none(changeset.is_document_empty);
    });

    // Use the temporary row meta to get rid of the lock that not implement the `Send` or 'Sync' trait.
    let row_detail = database.get_row_detail(row_id);
    drop(database);

    if let Some(row_detail) = row_detail {
      for view in self.database_views.editors().await {
        view.v_did_update_row_meta(row_id, &row_detail).await;
      }

      // Notifies the client that the row meta has been updated.
      send_notification(row_id.as_str(), DatabaseNotification::DidUpdateRowMeta)
        .payload(RowMetaPB::from(&row_detail))
        .send();

      // Update the last modified time of the row
      self
        .update_last_modified_time(row_detail.clone(), &changeset.view_id)
        .await;
    }
  }

  pub async fn get_cell(&self, field_id: &str, row_id: &RowId) -> Option<Cell> {
    let database = self.database.read().await;
    let field = database.get_field(field_id)?;
    let field_type = FieldType::from(field.field_type);
    // If the cell data is referenced, return the reference data. Otherwise, return an empty cell.
    match field_type {
      FieldType::LastEditedTime | FieldType::CreatedTime => {
        let row = database.get_row(row_id);
        let wrapped_cell_data = if field_type.is_created_time() {
          TimestampCellDataWrapper::from((field_type, TimestampCellData::new(row.created_at)))
        } else {
          TimestampCellDataWrapper::from((field_type, TimestampCellData::new(row.modified_at)))
        };
        Some(Cell::from(wrapped_cell_data))
      },
      _ => database.get_cell(field_id, row_id).cell,
    }
  }

  pub async fn get_cell_pb(&self, field_id: &str, row_id: &RowId) -> Option<CellPB> {
    let (field, cell) = {
      let cell = self.get_cell(field_id, row_id).await?;
      let field = self.database.read().await.get_field(field_id)?;
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
    let database = self.database.read().await;
    if let Some(field) = database.get_field(field_id) {
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

  #[instrument(level = "trace", skip_all)]
  pub async fn update_cell_with_changeset(
    &self,
    view_id: &str,
    row_id: &RowId,
    field_id: &str,
    cell_changeset: BoxAny,
  ) -> FlowyResult<()> {
    let (field, cell) = {
      let database = self.database.read().await;
      let field = match database.get_field(field_id) {
        Some(field) => Ok(field),
        None => {
          let msg = format!("Field with id:{} not found", &field_id);
          Err(FlowyError::internal().with_context(msg))
        },
      }?;
      (field, database.get_cell(field_id, row_id).cell)
    };

    let new_cell =
      apply_cell_changeset(cell_changeset, cell, &field, Some(self.cell_cache.clone()))?;
    self.update_cell(view_id, row_id, field_id, new_cell).await
  }

  async fn update_last_modified_time(&self, row_detail: RowDetail, view_id: &str) {
    self
      .database
      .write()
      .await
      .update_row(row_detail.row.id.clone(), |row_update| {
        row_update.set_last_modified(timestamp());
      });

    let editor = self.database_views.get_view_editor(view_id).await;
    if let Ok(editor) = editor {
      editor
        .v_did_update_row(&Some(row_detail.clone()), &row_detail, None)
        .await;
    }
  }

  /// Update a cell in the database.
  /// This will notify all views that the cell has been updated.
  pub async fn update_cell(
    &self,
    view_id: &str,
    row_id: &RowId,
    field_id: &str,
    new_cell: Cell,
  ) -> FlowyResult<()> {
    // Get the old row before updating the cell. It would be better to get the old cell
    let old_row = self.get_row_detail(view_id, row_id).await;
    self
      .database
      .write()
      .await
      .update_row(row_id.clone(), |row_update| {
        row_update.update_cells(|cell_update| {
          cell_update.insert(field_id, new_cell);
        });
      });

    self
      .did_update_row(view_id, row_id, field_id, old_row)
      .await;

    Ok(())
  }

  pub async fn clear_cell(&self, view_id: &str, row_id: RowId, field_id: &str) -> FlowyResult<()> {
    // Get the old row before updating the cell. It would be better to get the old cell
    let old_row = self.get_row_detail(view_id, &row_id).await;

    self
      .database
      .write()
      .await
      .update_row(row_id.clone(), |row_update| {
        row_update.update_cells(|cell_update| {
          cell_update.clear(field_id);
        });
      });

    self
      .did_update_row(view_id, &row_id, field_id, old_row)
      .await;

    Ok(())
  }

  async fn did_update_row(
    &self,
    view_id: &str,
    row_id: &RowId,
    field_id: &str,
    old_row: Option<RowDetail>,
  ) {
    let option_row = self.get_row_detail(view_id, row_id).await;
    if let Some(new_row_detail) = option_row {
      for view in self.database_views.editors().await {
        view
          .v_did_update_row(&old_row, &new_row_detail, Some(field_id.to_owned()))
          .await;
      }
    }
  }

  pub async fn get_auto_updated_fields_changesets(
    &self,
    view_id: &str,
    row_id: RowId,
  ) -> Vec<CellChangesetNotifyPB> {
    // Get all auto updated fields. It will be used to notify the frontend
    // that the fields have been updated.
    let auto_updated_fields = self.get_auto_updated_fields(view_id).await;

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
    let field = self.database.read().await.get_field(field_id)?;
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
    let mut database = self.database.write().await;
    let field = database.get_field(field_id).ok_or_else(|| {
      FlowyError::record_not_found().with_context(format!("Field with id:{} not found", &field_id))
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
    let view_editors = self.database_views.editors().await;
    update_field_type_option_fn(&mut database, type_option.to_type_option_data(), &field).await?;
    drop(database);

    for view_editor in view_editors {
      view_editor.v_did_update_field_type_option(&field).await?;
    }

    // Insert the options into the cell
    self
      .update_cell_with_changeset(view_id, &row_id, field_id, BoxAny::new(cell_changeset))
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
    let mut database = self.database.write().await;
    let field = match database.get_field(field_id) {
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

    let view_editors = self.database_views.editors().await;
    update_field_type_option_fn(&mut database, type_option.to_type_option_data(), &field).await?;

    // Drop the database write lock ASAP
    drop(database);

    for view_editor in view_editors {
      view_editor.v_did_update_field_type_option(&field).await?;
    }

    self
      .update_cell_with_changeset(view_id, &row_id, field_id, BoxAny::new(cell_changeset))
      .await?;
    Ok(())
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
      .read()
      .await
      .get_field(field_id)
      .ok_or_else(|| {
        FlowyError::record_not_found()
          .with_context(format!("Field with id:{} not found", &field_id))
      })?;
    debug_assert!(FieldType::from(field.field_type).is_checklist());

    self
      .update_cell_with_changeset(view_id, &row_id, field_id, BoxAny::new(changeset))
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
    let row_detail = self.get_row_detail(view_id, &from_row).await;
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
          self.move_row(view_id, from_row.clone(), row_id).await?;
        }

        if from_group == to_group {
          return Ok(());
        }

        tracing::trace!("Row data changed: {:?}", row_changeset);
        self
          .database
          .write()
          .await
          .update_row(row_detail.row.id, |row| {
            row.set_cells(Cells::from(row_changeset.cell_by_field_id.clone()));
          });
      },
    }

    Ok(())
  }

  pub async fn group_by_field(&self, view_id: &str, field_id: &str) -> FlowyResult<()> {
    let view = self.database_views.get_view_editor(view_id).await?;
    view.v_group_by_field(field_id).await?;
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
    let database_id = self.database.read().await.get_database_id();
    let index_field = IndexFieldPB {
      field: FieldPB::new(field),
      index: index as i32,
    };
    let notified_changeset = DatabaseFieldChangesetPB::insert(&database_id, vec![index_field]);
    let _ = self.notify_did_update_database(notified_changeset).await;
    Ok(())
  }

  async fn notify_did_update_database(
    &self,
    changeset: DatabaseFieldChangesetPB,
  ) -> FlowyResult<()> {
    let views = self.database.read().await.get_all_database_views_meta();
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
      .read()
      .await
      .get_view(view_id)
      .ok_or_else(|| FlowyError::record_not_found().with_context("Can't find the database view"))?;
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
      let database = self.database.read().await;
      let database_id = database.get_database_id();
      let fields = database
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
    let database_guard = database.read().await;
    let csv = CSVExport
      .export_database(&database_guard, style)
      .map_err(internal_error)?;
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
      .await
      .iter()
      .map(|field| field.id.clone())
      .collect();

    self.get_field_settings(view_id, field_ids).await
  }

  pub async fn update_field_settings_with_changeset(
    &self,
    params: FieldSettingsChangesetPB,
  ) -> FlowyResult<()> {
    let view = self.database_views.get_view_editor(&params.view_id).await?;
    view.v_update_field_settings(params).await?;

    Ok(())
  }

  pub async fn get_related_database_id(&self, field_id: &str) -> FlowyResult<String> {
    let mut field = self
      .database
      .read()
      .await
      .get_fields(Some(vec![field_id.to_string()]));
    let field = field.pop().ok_or(FlowyError::internal())?;

    let type_option = field
      .get_type_option::<RelationTypeOption>(FieldType::Relation)
      .ok_or(FlowyError::record_not_found())?;

    Ok(type_option.database_id)
  }

  pub async fn get_related_rows(
    &self,
    row_ids: Option<&Vec<String>>,
  ) -> FlowyResult<Vec<RelatedRowDataPB>> {
    let database = self.database.read().await;
    let primary_field = database.get_primary_field().unwrap();
    let handler = TypeOptionCellExt::new(&primary_field, Some(self.cell_cache.clone()))
      .get_type_option_cell_data_handler_with_field_type(FieldType::RichText)
      .ok_or(FlowyError::internal())?;

    let row_data = {
      let mut rows = database.get_database_rows();
      if let Some(row_ids) = row_ids {
        rows.retain(|row| row_ids.contains(&row.id));
      }
      rows
        .iter()
        .map(|row| {
          let title = database
            .get_cell(&primary_field.id, &row.id)
            .cell
            .and_then(|cell| handler.handle_get_boxed_cell_data(&cell, &primary_field))
            .and_then(|cell_data| cell_data.unbox_or_none())
            .unwrap_or_else(|| StringCellData("".to_string()));

          RelatedRowDataPB {
            row_id: row.id.to_string(),
            name: title.0,
          }
        })
        .collect::<Vec<_>>()
    };

    Ok(row_data)
  }

  async fn get_auto_updated_fields(&self, view_id: &str) -> Vec<Field> {
    self
      .database
      .read()
      .await
      .get_fields_in_view(view_id, None)
      .into_iter()
      .filter(|f| FieldType::from(f.field_type).is_auto_update())
      .collect::<Vec<Field>>()
  }

  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_mutex_database(&self) -> &RwLock<Database> {
    &self.database
  }
}

struct DatabaseViewOperationImpl {
  database: Arc<RwLock<Database>>,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  cell_cache: CellCache,
  editor_by_view_id: Arc<RwLock<EditorByViewId>>,
}

#[async_trait]
impl DatabaseViewOperation for DatabaseViewOperationImpl {
  fn get_database(&self) -> Arc<RwLock<Database>> {
    self.database.clone()
  }

  async fn get_view(&self, view_id: &str) -> Option<DatabaseView> {
    self.database.read().await.get_view(view_id)
  }

  async fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Vec<Field> {
    self
      .database
      .read()
      .await
      .get_fields_in_view(view_id, field_ids)
  }

  async fn get_field(&self, field_id: &str) -> Option<Field> {
    self.database.read().await.get_field(field_id)
  }

  async fn create_field(
    &self,
    view_id: &str,
    name: &str,
    field_type: FieldType,
    type_option_data: TypeOptionData,
  ) -> Field {
    let (_, field) = self.database.write().await.create_field_with_mut(
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
    field
  }

  async fn update_field(
    &self,
    type_option_data: TypeOptionData,
    old_field: Field,
  ) -> Result<(), FlowyError> {
    let view_editors = self
      .editor_by_view_id
      .read()
      .await
      .values()
      .cloned()
      .collect::<Vec<_>>();

    //
    {
      let mut database = self.database.write().await;
      let _ = update_field_type_option_fn(&mut *database, type_option_data, &old_field).await;
      drop(database);
    }

    for view_editor in view_editors {
      view_editor
        .v_did_update_field_type_option(&old_field)
        .await?;
    }
    Ok(())
  }

  async fn get_primary_field(&self) -> Option<Arc<Field>> {
    self.database.read().await.get_primary_field().map(Arc::new)
  }

  async fn index_of_row(&self, view_id: &str, row_id: &RowId) -> Option<usize> {
    self.database.read().await.index_of_row(view_id, row_id)
  }

  async fn get_row(&self, view_id: &str, row_id: &RowId) -> Option<(usize, Arc<RowDetail>)> {
    let database = self.database.read().await;
    let index = database.index_of_row(view_id, row_id);
    let row_detail = database.get_row_detail(row_id);
    match (index, row_detail) {
      (Some(index), Some(row_detail)) => Some((index, Arc::new(row_detail))),
      _ => None,
    }
  }

  async fn get_rows(&self, view_id: &str) -> Vec<Arc<RowDetail>> {
    let database = self.database.read().await;
    let view_id = view_id.to_string();
    // offloads the blocking operation to a thread where blocking is acceptable. This prevents
    // blocking the main asynchronous runtime
    let row_orders = database.get_row_orders_for_view(&view_id);

    let mut all_rows = vec![];

    // Loading the rows in chunks of 10 rows in order to prevent blocking the main asynchronous runtime
    for chunk in row_orders.chunks(10) {
      let chunk = chunk.to_vec();
      let rows = {
        let orders = database.get_rows_from_row_orders(&chunk);
        orders
          .into_iter()
          .flat_map(|row| database.get_row_detail(&row.id))
          .collect::<Vec<RowDetail>>()
      };

      all_rows.extend(rows);
      tokio::task::yield_now().await;
    }

    all_rows.into_iter().map(Arc::new).collect()
  }

  async fn remove_row(&self, row_id: &RowId) -> Option<Row> {
    self.database.write().await.remove_row(row_id)
  }

  async fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Vec<Arc<RowCell>> {
    let cells = self
      .database
      .read()
      .await
      .get_cells_for_field(view_id, field_id);
    cells.into_iter().map(Arc::new).collect()
  }

  async fn get_cell_in_row(&self, field_id: &str, row_id: &RowId) -> Arc<RowCell> {
    let cell = self.database.read().await.get_cell(field_id, row_id);
    cell.into()
  }

  async fn get_layout_for_view(&self, view_id: &str) -> DatabaseLayout {
    self.database.read().await.get_database_view_layout(view_id)
  }

  async fn get_group_setting(&self, view_id: &str) -> Vec<GroupSetting> {
    self.database.read().await.get_all_group_setting(view_id)
  }

  async fn insert_group_setting(&self, view_id: &str, setting: GroupSetting) {
    self
      .database
      .write()
      .await
      .insert_group_setting(view_id, setting);
  }

  async fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Sort> {
    self
      .database
      .read()
      .await
      .get_sort::<Sort>(view_id, sort_id)
  }

  async fn insert_sort(&self, view_id: &str, sort: Sort) {
    self.database.write().await.insert_sort(view_id, sort);
  }

  async fn move_sort(&self, view_id: &str, from_sort_id: &str, to_sort_id: &str) {
    self
      .database
      .write()
      .await
      .move_sort(view_id, from_sort_id, to_sort_id);
  }

  async fn remove_sort(&self, view_id: &str, sort_id: &str) {
    self.database.write().await.remove_sort(view_id, sort_id);
  }

  async fn get_all_sorts(&self, view_id: &str) -> Vec<Sort> {
    self.database.read().await.get_all_sorts::<Sort>(view_id)
  }

  async fn remove_all_sorts(&self, view_id: &str) {
    self.database.write().await.remove_all_sorts(view_id);
  }

  async fn get_all_calculations(&self, view_id: &str) -> Vec<Arc<Calculation>> {
    self
      .database
      .read()
      .await
      .get_all_calculations(view_id)
      .into_iter()
      .map(Arc::new)
      .collect()
  }

  async fn get_calculation(&self, view_id: &str, field_id: &str) -> Option<Calculation> {
    self
      .database
      .read()
      .await
      .get_calculation::<Calculation>(view_id, field_id)
  }

  async fn get_all_filters(&self, view_id: &str) -> Vec<Filter> {
    self
      .database
      .read()
      .await
      .get_all_filters(view_id)
      .into_iter()
      .collect()
  }

  async fn delete_filter(&self, view_id: &str, filter_id: &str) {
    self
      .database
      .write()
      .await
      .remove_filter(view_id, filter_id);
  }

  async fn insert_filter(&self, view_id: &str, filter: Filter) {
    self.database.write().await.insert_filter(view_id, &filter);
  }

  async fn save_filters(&self, view_id: &str, filters: &[Filter]) {
    self
      .database
      .write()
      .await
      .save_filters::<Filter, FilterMap>(view_id, filters);
  }

  async fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter> {
    self
      .database
      .read()
      .await
      .get_filter::<Filter>(view_id, filter_id)
  }

  async fn get_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &DatabaseLayout,
  ) -> Option<LayoutSetting> {
    self
      .database
      .read()
      .await
      .get_layout_setting(view_id, layout_ty)
  }

  async fn insert_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &DatabaseLayout,
    layout_setting: LayoutSetting,
  ) {
    self
      .database
      .write()
      .await
      .insert_layout_setting(view_id, layout_ty, layout_setting);
  }

  async fn update_layout_type(&self, view_id: &str, layout_type: &DatabaseLayout) {
    self
      .database
      .write()
      .await
      .update_layout_type(view_id, layout_type);
  }

  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>> {
    self.task_scheduler.clone()
  }

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>> {
    TypeOptionCellExt::new(field, Some(self.cell_cache.clone())).get_type_option_cell_data_handler()
  }

  async fn get_field_settings(
    &self,
    view_id: &str,
    field_ids: &[String],
  ) -> HashMap<String, FieldSettings> {
    let (layout_type, field_settings_map) = {
      let database = self.database.read().await;
      let layout_type = database.get_database_view_layout(view_id);
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

  async fn update_field_settings(&self, params: FieldSettingsChangesetPB) {
    let field_settings_map = self
      .get_field_settings(&params.view_id, &[params.field_id.clone()])
      .await;

    let field_settings = match field_settings_map.get(&params.field_id).cloned() {
      Some(field_settings) => field_settings,
      None => {
        let layout_type = self.get_layout_for_view(&params.view_id).await;
        let default_field_settings = default_field_settings_by_layout_map();
        let default_field_settings = default_field_settings.get(&layout_type).unwrap();
        FieldSettings::from_any_map(&params.field_id, layout_type, default_field_settings)
      },
    };

    let new_field_settings = FieldSettings {
      visibility: params
        .visibility
        .unwrap_or_else(|| field_settings.visibility.clone()),
      width: params.width.unwrap_or(field_settings.width),
      wrap_cell_content: params
        .wrap_cell_content
        .unwrap_or(field_settings.wrap_cell_content),
      ..field_settings
    };

    self.database.write().await.update_field_settings(
      &params.view_id,
      Some(vec![params.field_id]),
      new_field_settings.clone(),
    );

    send_notification(
      &params.view_id,
      DatabaseNotification::DidUpdateFieldSettings,
    )
    .payload(FieldSettingsPB::from(new_field_settings))
    .send()
  }

  async fn update_calculation(&self, view_id: &str, calculation: Calculation) {
    self
      .database
      .write()
      .await
      .update_calculation(view_id, calculation)
  }

  async fn remove_calculation(&self, view_id: &str, field_id: &str) {
    self
      .database
      .write()
      .await
      .remove_calculation(view_id, field_id)
  }
}

#[tracing::instrument(level = "trace", skip_all, err)]
pub async fn update_field_type_option_fn(
  database: &mut Database,
  type_option_data: TypeOptionData,
  old_field: &Field,
) -> FlowyResult<()> {
  if type_option_data.is_empty() {
    warn!("Update type option with empty data");
    return Ok(());
  }
  let field_type = FieldType::from(old_field.field_type.clone());
  database.update_field(&old_field.id, |update| {
    if old_field.is_primary {
      warn!("Cannot update primary field type");
    } else {
      update.update_type_options(|type_options_update| {
        event!(
          tracing::Level::TRACE,
          "insert type option to field type: {:?}, {:?}",
          field_type,
          type_option_data
        );
        type_options_update.insert(&field_type.to_string(), type_option_data);
      });
    }
  });

  let _ = notify_did_update_database_field(database, &old_field.id);
  Ok(())
}

#[tracing::instrument(level = "trace", skip_all, err)]
fn notify_did_update_database_field(database: &Database, field_id: &str) -> FlowyResult<()> {
  let (database_id, field, views) = {
    let database_id = database.get_database_id();
    let field = database.get_field(field_id);
    let views = database.get_all_database_views_meta();
    (database_id, field, views)
  };

  if let Some(field) = field {
    let updated_field = FieldPB::new(field);
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
