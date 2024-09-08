use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

use super::{notify_did_rename_group, notify_did_update_calculation};
use crate::entities::{
  CalendarEventPB, CreateRowParams, CreateRowPayloadPB, DatabaseLayoutMetaPB,
  DatabaseLayoutSettingPB, DeleteSortPayloadPB, FieldSettingsChangesetPB, FieldType,
  GroupChangesPB, GroupPB, GroupRenameNotificationPB, LayoutSettingChangeset, LayoutSettingParams,
  RemoveCalculationChangesetPB, ReorderSortPayloadPB, RowMetaPB, RowsChangePB,
  SortChangesetNotificationPB, SortPB, UpdateCalculationChangesetPB, UpdateSortPayloadPB,
};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::calculations::{Calculation, CalculationChangeset, CalculationsController};
use crate::services::cell::{CellBuilder, CellCache};
use crate::services::database::{database_view_setting_pb_from_view, DatabaseRowEvent, UpdatedRow};
use crate::services::database_view::view_calculations::make_calculations_controller;
use crate::services::database_view::view_filter::make_filter_controller;
use crate::services::database_view::view_group::{
  get_cell_for_row, get_cells_for_field, new_group_controller,
};
use crate::services::database_view::view_operation::DatabaseViewOperation;
use crate::services::database_view::view_sort::make_sort_controller;
use crate::services::database_view::{
  notify_did_update_filter, notify_did_update_group_rows, notify_did_update_num_of_groups,
  notify_did_update_setting, notify_did_update_sort, DatabaseLayoutDepsResolver,
  DatabaseViewChangedNotifier, DatabaseViewChangedReceiverRunner,
};
use crate::services::field::{MultiSelectTypeOption, SingleSelectTypeOption};
use crate::services::field_settings::FieldSettings;
use crate::services::filter::{Filter, FilterChangeset, FilterController};
use crate::services::group::{
  DidMoveGroupRowResult, GroupChangeset, GroupController, MoveGroupRowContext, UpdatedCells,
};
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::{Sort, SortChangeset, SortController};
use collab_database::database::{gen_database_calculation_id, gen_database_sort_id, gen_row_id};
use collab_database::entity::DatabaseView;
use collab_database::fields::Field;
use collab_database::rows::{Cells, Row, RowDetail, RowId};
use collab_database::views::{DatabaseLayout, RowOrder};
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use lib_infra::util::timestamp;
use tokio::sync::{broadcast, RwLock};
use tracing::{instrument, trace};

pub struct DatabaseViewEditor {
  database_id: String,
  pub view_id: String,
  delegate: Arc<dyn DatabaseViewOperation>,
  group_controller: Arc<RwLock<Option<Box<dyn GroupController>>>>,
  filter_controller: Arc<FilterController>,
  sort_controller: Arc<RwLock<SortController>>,
  calculations_controller: Arc<CalculationsController>,
  /// Use lazy_rows as cache that represents the row's order for given view
  /// It can't get the row id when deleting a row. it only returns the deleted index.
  /// So using this cache to get the row id by index
  ///
  /// Check out this link (https://github.com/y-crdt/y-crdt/issues/341) for more information.
  pub(crate) row_orders: RwLock<Vec<RowOrder>>,
  pub(crate) row_by_row_id: DashMap<String, Arc<Row>>,
  pub notifier: DatabaseViewChangedNotifier,
}

impl Drop for DatabaseViewEditor {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl DatabaseViewEditor {
  pub async fn new(
    database_id: String,
    view_id: String,
    delegate: Arc<dyn DatabaseViewOperation>,
    cell_cache: CellCache,
  ) -> FlowyResult<Self> {
    let (notifier, _) = broadcast::channel(100);
    tokio::spawn(DatabaseViewChangedReceiverRunner(Some(notifier.subscribe())).run());

    // Filter
    let filter_controller = make_filter_controller(
      &view_id,
      delegate.clone(),
      notifier.clone(),
      cell_cache.clone(),
    )
    .await;

    // Sort
    let sort_controller = make_sort_controller(
      &view_id,
      delegate.clone(),
      notifier.clone(),
      filter_controller.clone(),
      cell_cache,
    )
    .await;

    // Group
    let group_controller = Arc::new(RwLock::new(
      new_group_controller(
        view_id.clone(),
        delegate.clone(),
        filter_controller.clone(),
        None,
      )
      .await?,
    ));

    // Calculations
    let calculations_controller =
      make_calculations_controller(&view_id, delegate.clone(), notifier.clone()).await;

    Ok(Self {
      database_id,
      view_id,
      delegate,
      group_controller,
      filter_controller,
      sort_controller,
      calculations_controller,
      row_orders: Default::default(),
      row_by_row_id: Default::default(),
      notifier,
    })
  }

  pub async fn set_row_orders(&self, row_orders: Vec<RowOrder>) {
    *self.row_orders.write().await = row_orders;
  }

  pub async fn get_all_row_orders(&self) -> FlowyResult<Vec<RowOrder>> {
    let row_orders = self.delegate.get_all_row_orders(&self.view_id).await;
    Ok(row_orders)
  }

  pub async fn close(&self) {
    self.sort_controller.write().await.close().await;
    self.filter_controller.close().await;
    self.calculations_controller.close().await;
  }

  pub async fn has_filters(&self) -> bool {
    self.filter_controller.has_filters().await
  }

  pub async fn has_sorts(&self) -> bool {
    self.sort_controller.read().await.has_sorts().await
  }

  pub async fn v_get_view(&self) -> Option<DatabaseView> {
    self.delegate.get_view(&self.view_id).await
  }

  pub async fn v_will_create_row(
    &self,
    params: CreateRowPayloadPB,
  ) -> FlowyResult<CreateRowParams> {
    let timestamp = timestamp();
    let mut result = CreateRowParams {
      collab_params: collab_database::rows::CreateRowParams {
        id: gen_row_id(),
        database_id: self.database_id.clone(),
        cells: Cells::new(),
        height: 60,
        visibility: true,
        row_position: params.row_position.try_into()?,
        created_at: timestamp,
        modified_at: timestamp,
      },
      open_after_create: false,
    };

    // fill in cells from the frontend
    let fields = self.delegate.get_fields(&params.view_id, None).await;
    let mut cells = CellBuilder::with_cells(params.data, &fields).build();

    // fill in cells according to group_id if supplied
    if let Some(group_id) = params.group_id {
      if let Some(controller) = self.group_controller.read().await.as_ref() {
        let field = self
          .delegate
          .get_field(controller.get_grouping_field_id())
          .await
          .ok_or_else(|| FlowyError::internal().with_context("Failed to get grouping field"))?;
        controller.will_create_row(&mut cells, &field, &group_id);
      }
    }

    // fill in cells according to active filters
    let filter_controller = self.filter_controller.clone();
    filter_controller.fill_cells(&mut cells).await;

    result.collab_params.cells = cells;
    Ok(result)
  }

  pub async fn v_did_update_row_meta(&self, row_id: &RowId, row_detail: &RowDetail) {
    let update_row = UpdatedRow::new(row_id.as_str()).with_row_meta(row_detail.clone());
    let changeset = RowsChangePB::from_update(update_row.into());
    send_notification(&self.view_id, DatabaseNotification::DidUpdateRow)
      .payload(changeset)
      .send();
  }

  pub async fn v_did_create_row(
    &self,
    row: &Row,
    index: u32,
    is_move_row: bool,
    is_local_change: bool,
  ) {
    // Send the group notification if the current view has groups

    if !is_move_row || !is_local_change {
      if let Some(controller) = self.group_controller.write().await.as_mut() {
        let mut rows = vec![Arc::new(row.clone())];
        self.v_filter_rows(&mut rows).await;
        if let Some(row) = rows.pop() {
          let changesets = controller.did_create_row(&row, index as usize);
          for changeset in changesets {
            notify_did_update_group_rows(changeset).await;
          }
        }
      }
    }

    self.gen_did_create_row_view_tasks(index, row.clone()).await;
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_did_delete_row(&self, row: &Row, is_move_row: bool, is_local_change: bool) {
    let deleted_row = row.clone();

    // Only update group rows
    // 1. when the row is deleted locally. If the row is moved, we don't need to send the group
    // notification. Because it's handled by the move_group_row function
    // 2. when the row is deleted remotely
    if !is_move_row || !is_local_change {
      // Send the group notification if the current view has groups;
      let result = self
        .mut_group_controller(|group_controller, _| group_controller.did_delete_row(row))
        .await;
      handle_mut_group_result(&self.view_id, result).await;
    }

    // Updating calculations for each of the Rows cells is a tedious task
    // Therefore we spawn a separate task for this
    let weak_calculations_controller = Arc::downgrade(&self.calculations_controller);
    tokio::spawn(async move {
      if let Some(calculations_controller) = weak_calculations_controller.upgrade() {
        calculations_controller
          .did_receive_row_changed(deleted_row)
          .await;
      }
    });
  }

  /// Notify the view that the row has been updated. If the view has groups,
  /// send the group notification with [GroupRowsNotificationPB]. Otherwise,
  /// send the view notification with [RowsChangePB]
  #[instrument(level = "trace", skip_all)]
  pub async fn v_did_update_row(&self, old_row: &Option<Row>, row: &Row, field_id: Option<String>) {
    if let Some(controller) = self.group_controller.write().await.as_mut() {
      let field = self
        .delegate
        .get_field(controller.get_grouping_field_id())
        .await;

      if let Some(field) = field {
        let mut rows = vec![Arc::new(row.clone())];
        self.v_filter_rows(&mut rows).await;

        if let Some(row) = rows.pop() {
          let result = controller.did_update_group_row(old_row, &row, &field);

          if let Ok(result) = result {
            let mut group_changes = GroupChangesPB {
              view_id: self.view_id.clone(),
              ..Default::default()
            };
            if let Some(inserted_group) = result.inserted_group {
              tracing::trace!("Create group after editing the row: {:?}", inserted_group);
              group_changes.inserted_groups.push(inserted_group);
            }
            if let Some(delete_group) = result.deleted_group {
              tracing::trace!("Delete group after editing the row: {:?}", delete_group);
              group_changes.deleted_groups.push(delete_group.group_id);
            }

            if !group_changes.is_empty() {
              notify_did_update_num_of_groups(&self.view_id, group_changes).await;
            }

            for changeset in result.row_changesets {
              if !changeset.is_empty() {
                tracing::trace!("Group change after editing the row: {:?}", changeset);
                notify_did_update_group_rows(changeset).await;
              }
            }
          }
        }
      }
    }

    // Each row update will trigger a calculations, filter and sort operation. We don't want
    // to block the main thread, so we spawn a new task to do the work.
    self
      .gen_did_update_row_view_tasks(row.id.clone(), field_id)
      .await;
  }

  pub async fn v_filter_rows(&self, rows: &mut Vec<Arc<Row>>) {
    self.filter_controller.filter_rows(rows).await
  }

  pub async fn v_filter_rows_and_notify(&self, rows: &mut Vec<Arc<Row>>) {
    let _ = self.filter_controller.filter_rows_and_notify(rows).await;
  }

  pub async fn v_sort_rows(&self, rows: &mut Vec<Arc<Row>>) {
    self.sort_controller.write().await.sort_rows(rows).await
  }

  pub async fn v_sort_rows_and_notify(&self, rows: &mut Vec<Arc<Row>>) {
    self
      .sort_controller
      .write()
      .await
      .sort_rows_and_notify(rows)
      .await;
  }

  #[instrument(level = "info", skip(self))]
  pub async fn v_get_all_rows(&self) -> Vec<Arc<Row>> {
    let row_orders = self.delegate.get_all_row_orders(&self.view_id).await;
    let mut rows = self.delegate.get_all_rows(&self.view_id, row_orders).await;
    self.v_filter_rows(&mut rows).await;
    self.v_sort_rows(&mut rows).await;
    rows
  }

  pub async fn v_get_row(&self, row_id: &RowId) -> Option<(usize, Arc<RowDetail>)> {
    self.delegate.get_row_detail(&self.view_id, row_id).await
  }

  pub async fn v_move_group_row(
    &self,
    row: &Row,
    to_group_id: &str,
    to_row_id: Option<RowId>,
  ) -> UpdatedCells {
    let mut updated_cells = UpdatedCells::new();
    let result = self
      .mut_group_controller(|group_controller, field| {
        let move_row_context = MoveGroupRowContext {
          row,
          updated_cells: &mut updated_cells,
          field: &field,
          to_group_id,
          to_row_id,
        };
        group_controller.move_group_row(move_row_context)
      })
      .await;

    handle_mut_group_result(&self.view_id, result).await;
    updated_cells
  }

  /// Only call once after database view editor initialized
  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn v_load_groups(&self) -> Option<Vec<GroupPB>> {
    let groups = self
      .group_controller
      .read()
      .await
      .as_ref()?
      .get_all_groups()
      .into_iter()
      .map(|group_data| GroupPB::from(group_data.clone()))
      .collect::<Vec<_>>();
    tracing::trace!("Number of groups: {}", groups.len());
    Some(groups)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn v_get_group(&self, group_id: &str) -> FlowyResult<GroupPB> {
    match self
      .group_controller
      .read()
      .await
      .as_ref()
      .and_then(|group| group.get_group(group_id))
    {
      None => Err(FlowyError::record_not_found().with_context("Can't find the group")),
      Some((_, group)) => Ok(GroupPB::from(group)),
    }
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_move_group(&self, from_group: &str, to_group: &str) -> FlowyResult<()> {
    self
      .mut_group_controller(|group_controller, _| group_controller.move_group(from_group, to_group))
      .await;
    Ok(())
  }

  pub async fn is_grouping_field(&self, field_id: &str) -> bool {
    match self.group_controller.read().await.as_ref() {
      Some(group_controller) => group_controller.get_grouping_field_id() == field_id,
      None => false,
    }
  }

  /// Called when the user changes the grouping field
  pub async fn v_initialize_new_group(&self, field_id: &str) -> FlowyResult<()> {
    if let Some(view) = self.delegate.get_view(&self.view_id).await {
      let setting = database_view_setting_pb_from_view(view);
      notify_did_update_setting(&self.view_id, setting).await;
    }

    self.v_group_by_field(field_id).await?;
    Ok(())
  }

  pub async fn v_create_group(&self, name: &str) -> FlowyResult<()> {
    let mut old_field: Option<Field> = None;
    let result = if let Some(controller) = self.group_controller.write().await.as_mut() {
      let create_group_results = controller.create_group(name.to_string()).await?;
      old_field = self
        .delegate
        .get_field(controller.get_grouping_field_id())
        .await;
      create_group_results
    } else {
      (None, None)
    };

    if let Some(old_field) = old_field {
      if let (Some(type_option_data), Some(payload)) = result {
        self
          .delegate
          .update_field(type_option_data, old_field)
          .await?;

        let group_changes = GroupChangesPB {
          view_id: self.view_id.clone(),
          inserted_groups: vec![payload],
          ..Default::default()
        };

        notify_did_update_num_of_groups(&self.view_id, group_changes).await;
      }
    }

    Ok(())
  }

  pub async fn v_delete_group(&self, group_id: &str) -> FlowyResult<RowsChangePB> {
    let mut group_controller = self.group_controller.write().await;
    let controller = match group_controller.as_mut() {
      Some(controller) => controller,
      None => return Ok(RowsChangePB::default()),
    };

    let old_field = self
      .delegate
      .get_field(controller.get_grouping_field_id())
      .await;
    let (row_ids, type_option_data) = controller.delete_group(group_id).await?;

    drop(group_controller);

    let mut changes = RowsChangePB::default();
    if let Some(field) = old_field {
      for row_id in row_ids {
        if let Some(row) = self.delegate.remove_row(&row_id).await {
          changes.deleted_rows.push(row.id.into_inner());
        }
      }

      if let Some(type_option) = type_option_data {
        self.delegate.update_field(type_option, field).await?;
      }
      let notification = GroupChangesPB {
        view_id: self.view_id.clone(),
        deleted_groups: vec![group_id.to_string()],
        ..Default::default()
      };
      notify_did_update_num_of_groups(&self.view_id, notification).await;
    }

    Ok(changes)
  }

  pub async fn v_update_group(&self, changeset: Vec<GroupChangeset>) -> FlowyResult<()> {
    let mut type_option_data = None;
    let (old_field, updated_groups) = if let Some(controller) =
      self.group_controller.write().await.as_mut()
    {
      let old_field = self
        .delegate
        .get_field(controller.get_grouping_field_id())
        .await;
      let (updated_groups, new_type_option) = controller.apply_group_changeset(&changeset).await?;

      if new_type_option.is_some() {
        type_option_data = new_type_option;
      }

      (old_field, updated_groups)
    } else {
      (None, vec![])
    };

    if let Some(old_field) = old_field {
      if let Some(type_option_data) = type_option_data {
        self
          .delegate
          .update_field(type_option_data, old_field)
          .await?;
      }
      let notification = GroupChangesPB {
        view_id: self.view_id.clone(),
        update_groups: updated_groups,
        ..Default::default()
      };
      notify_did_update_num_of_groups(&self.view_id, notification).await;
    }

    Ok(())
  }

  pub async fn v_rename_group(&self, changeset: GroupChangeset) -> FlowyResult<()> {
    let mut type_option_data = None;
    let (old_field, updated_group) =
      if let Some(controller) = self.group_controller.write().await.as_mut() {
        let old_field = self
          .delegate
          .get_field(controller.get_grouping_field_id())
          .await;
        let (updated_group, new_type_option) = controller.apply_group_rename(&changeset).await?;

        if new_type_option.is_some() {
          type_option_data = new_type_option;
        }

        (old_field, Some(updated_group))
      } else {
        (None, None)
      };

    if let (Some(old_field), Some(updated_group)) = (old_field, updated_group) {
      if let Some(type_option_data) = type_option_data {
        self
          .delegate
          .update_field(type_option_data, old_field)
          .await?;
      }

      let notification = GroupRenameNotificationPB {
        view_id: self.view_id.clone(),
        group_id: updated_group.group_id.clone(),
      };
      notify_did_rename_group(&self.view_id, notification).await;
    }

    Ok(())
  }

  pub async fn v_get_all_sorts(&self) -> Vec<Sort> {
    self.delegate.get_all_sorts(&self.view_id).await
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_create_or_update_sort(&self, params: UpdateSortPayloadPB) -> FlowyResult<Sort> {
    let is_exist = params.sort_id.is_some();
    let sort_id = match params.sort_id {
      None => gen_database_sort_id(),
      Some(sort_id) => sort_id,
    };

    let sort = Sort {
      id: sort_id,
      field_id: params.field_id.clone(),
      condition: params.condition.into(),
    };

    self.delegate.insert_sort(&self.view_id, sort.clone()).await;
    let mut sort_controller = self.sort_controller.write().await;
    let notification = if is_exist {
      sort_controller
        .apply_changeset(SortChangeset::from_update(sort.clone()))
        .await
    } else {
      sort_controller
        .apply_changeset(SortChangeset::from_insert(sort.clone()))
        .await
    };
    drop(sort_controller);
    notify_did_update_sort(notification).await;
    Ok(sort)
  }

  pub async fn v_reorder_sort(&self, params: ReorderSortPayloadPB) -> FlowyResult<()> {
    self
      .delegate
      .move_sort(&self.view_id, &params.from_sort_id, &params.to_sort_id)
      .await;

    let notification = self
      .sort_controller
      .write()
      .await
      .apply_changeset(SortChangeset::from_reorder(
        params.from_sort_id,
        params.to_sort_id,
      ))
      .await;

    notify_did_update_sort(notification).await;
    Ok(())
  }

  pub async fn v_delete_sort(&self, params: DeleteSortPayloadPB) -> FlowyResult<()> {
    let notification = self
      .sort_controller
      .write()
      .await
      .apply_changeset(SortChangeset::from_delete(params.sort_id.clone()))
      .await;

    self
      .delegate
      .remove_sort(&self.view_id, &params.sort_id)
      .await;
    notify_did_update_sort(notification).await;

    Ok(())
  }

  pub async fn v_delete_all_sorts(&self) -> FlowyResult<()> {
    let all_sorts = self.v_get_all_sorts().await;
    self.sort_controller.write().await.delete_all_sorts().await;

    self.delegate.remove_all_sorts(&self.view_id).await;
    let mut notification = SortChangesetNotificationPB::new(self.view_id.clone());
    notification.delete_sorts = all_sorts.into_iter().map(SortPB::from).collect();
    notify_did_update_sort(notification).await;
    Ok(())
  }

  pub async fn v_get_all_calculations(&self) -> Vec<Arc<Calculation>> {
    self.delegate.get_all_calculations(&self.view_id).await
  }

  pub async fn v_update_calculations(
    &self,
    params: UpdateCalculationChangesetPB,
  ) -> FlowyResult<()> {
    let calculation_id = match params.calculation_id {
      None => gen_database_calculation_id(),
      Some(calculation_id) => calculation_id,
    };

    let calculation = Calculation::none(
      calculation_id,
      params.field_id,
      Some(params.calculation_type.value()),
    );

    let changeset = self
      .calculations_controller
      .did_receive_changes(CalculationChangeset::from_insert(calculation.clone()))
      .await;

    if let Some(changeset) = changeset {
      if !changeset.insert_calculations.is_empty() {
        for insert in changeset.insert_calculations.clone() {
          let calculation: Calculation = Calculation::from(&insert);
          self
            .delegate
            .update_calculation(&params.view_id, calculation)
            .await;
        }
      }

      notify_did_update_calculation(changeset).await;
    }

    Ok(())
  }

  pub async fn v_remove_calculation(
    &self,
    params: RemoveCalculationChangesetPB,
  ) -> FlowyResult<()> {
    self
      .delegate
      .remove_calculation(&params.view_id, &params.calculation_id)
      .await;

    let calculation = Calculation::none(params.calculation_id, params.field_id, None);

    let changeset = self
      .calculations_controller
      .did_receive_changes(CalculationChangeset::from_delete(calculation.clone()))
      .await;

    if let Some(changeset) = changeset {
      notify_did_update_calculation(changeset).await;
    }

    Ok(())
  }

  pub async fn v_get_all_filters(&self) -> Vec<Filter> {
    self.delegate.get_all_filters(&self.view_id).await
  }

  pub async fn v_get_filter(&self, filter_id: &str) -> Option<Filter> {
    self.delegate.get_filter(&self.view_id, filter_id).await
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_modify_filters(&self, changeset: FilterChangeset) -> FlowyResult<()> {
    let notification = self.filter_controller.apply_changeset(changeset).await;
    notify_did_update_filter(notification).await;

    let group_controller_read_guard = self.group_controller.read().await;
    let grouping_field_id = group_controller_read_guard
      .as_ref()
      .map(|controller| controller.get_grouping_field_id().to_string());
    drop(group_controller_read_guard);

    if let Some(field_id) = grouping_field_id {
      self.v_group_by_field(&field_id).await?;
    }

    Ok(())
  }

  /// Returns the current calendar settings
  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn v_get_layout_settings(&self, layout_ty: &DatabaseLayout) -> LayoutSettingParams {
    let mut layout_setting = LayoutSettingParams::default();
    match layout_ty {
      DatabaseLayout::Grid => {},
      DatabaseLayout::Board => {
        if let Some(value) = self
          .delegate
          .get_layout_setting(&self.view_id, layout_ty)
          .await
        {
          layout_setting.board = Some(value.into());
        }
      },
      DatabaseLayout::Calendar => {
        if let Some(value) = self
          .delegate
          .get_layout_setting(&self.view_id, layout_ty)
          .await
        {
          let calendar_setting = CalendarLayoutSetting::from(value);
          // Check the field exist or not
          if let Some(field) = self.delegate.get_field(&calendar_setting.field_id).await {
            let field_type = FieldType::from(field.field_type);

            // Check the type of field is Datetime or not
            if field_type == FieldType::DateTime {
              layout_setting.calendar = Some(calendar_setting);
            } else {
              tracing::warn!("The field of calendar setting is not datetime type")
            }
          } else {
            tracing::warn!("The field of calendar setting is not exist");
          }
        }
      },
    }

    layout_setting
  }

  /// Update the layout settings and send the notification to refresh the UI
  pub async fn v_set_layout_settings(&self, params: LayoutSettingChangeset) -> FlowyResult<()> {
    if self.v_get_layout_type().await != params.layout_type || !params.is_valid() {
      return Err(FlowyError::invalid_data());
    }

    let layout_setting_pb = match params.layout_type {
      DatabaseLayout::Board => {
        let layout_setting = params.board.unwrap();

        self
          .delegate
          .insert_layout_setting(
            &self.view_id,
            &params.layout_type,
            layout_setting.clone().into(),
          )
          .await;

        Some(DatabaseLayoutSettingPB::from_board(layout_setting))
      },
      DatabaseLayout::Calendar => {
        let layout_setting = params.calendar.unwrap();

        if let Some(field) = self.delegate.get_field(&layout_setting.field_id).await {
          if FieldType::from(field.field_type) != FieldType::DateTime {
            return Err(FlowyError::unexpect_calendar_field_type());
          }

          self
            .delegate
            .insert_layout_setting(
              &self.view_id,
              &params.layout_type,
              layout_setting.clone().into(),
            )
            .await;

          Some(DatabaseLayoutSettingPB::from_calendar(layout_setting))
        } else {
          None
        }
      },
      _ => None,
    };

    if let Some(payload) = layout_setting_pb {
      send_notification(&self.view_id, DatabaseNotification::DidUpdateLayoutSettings)
        .payload(payload)
        .send();
    }

    Ok(())
  }

  pub async fn v_did_delete_field(&self, deleted_field_id: &str) {
    let changeset = FilterChangeset::DeleteAllWithFieldId {
      field_id: deleted_field_id.to_string(),
    };
    let notification = self.filter_controller.apply_changeset(changeset).await;
    notify_did_update_filter(notification).await;

    let sorts = self.delegate.get_all_sorts(&self.view_id).await;

    if let Some(sort) = sorts.iter().find(|sort| sort.field_id == deleted_field_id) {
      self.delegate.remove_sort(&self.view_id, &sort.id).await;
      let notification = self
        .sort_controller
        .write()
        .await
        .apply_changeset(SortChangeset::from_delete(sort.id.clone()))
        .await;
      if !notification.is_empty() {
        notify_did_update_sort(notification).await;
      }
    }

    self
      .calculations_controller
      .did_receive_field_deleted(deleted_field_id.to_string())
      .await;
  }

  pub async fn v_did_update_field_type(&self, field_id: &str, new_field_type: FieldType) {
    self
      .sort_controller
      .read()
      .await
      .did_update_field_type()
      .await;
    self
      .calculations_controller
      .did_receive_field_type_changed(field_id.to_owned(), new_field_type)
      .await;
  }

  /// Notifies the view's field type-option data is changed
  /// For the moment, only the groups will be generated after the type-option data changed. A
  /// [Field] has a property named type_options contains a list of type-option data.
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn v_did_update_field_type_option(&self, old_field: &Field) -> FlowyResult<()> {
    let field_id = &old_field.id;

    if let Some(field) = self.delegate.get_field(field_id).await {
      self
        .sort_controller
        .read()
        .await
        .did_update_field_type_option(&field)
        .await;

      if old_field.field_type != field.field_type {
        let changeset = FilterChangeset::DeleteAllWithFieldId {
          field_id: field.id.clone(),
        };
        let notification = self.filter_controller.apply_changeset(changeset).await;
        notify_did_update_filter(notification).await;
      }

      // If the id of the grouping field is equal to the updated field's id
      // and something critical changed, then we need to update the group setting
      if self.is_grouping_field(field_id).await
        && self.did_type_options_change(field.field_type.into(), old_field, &field)
      {
        self.v_group_by_field(field_id).await?;
      }
    }

    Ok(())
  }

  /// This method returns true if the field type options have changed enough to warrant
  /// updating the group by field in the client.
  ///
  /// This check should only be done when the field is the grouping field, and will by default
  /// return false for fields that don't quality to be grouped by.
  ///
  fn did_type_options_change(
    &self,
    field_type: FieldType,
    old_field: &Field,
    new_field: &Field,
  ) -> bool {
    if old_field.field_type != new_field.field_type {
      return true;
    }

    if !field_type.can_be_group() {
      return false;
    }

    match field_type {
      // Checkbox & Url can also be grouped by, but they work differently to select fields
      // and thus don't need to be updated when the type option itself changes
      FieldType::Checkbox | FieldType::URL => false,
      FieldType::SingleSelect => {
        let old_field_type_option = old_field.get_type_option::<SingleSelectTypeOption>(field_type);
        let new_field_type_option = new_field.get_type_option::<SingleSelectTypeOption>(field_type);

        if let (Some(old_field_type_option), Some(new_field_type_option)) =
          (old_field_type_option, new_field_type_option)
        {
          return old_field_type_option.options.len() != new_field_type_option.options.len();
        }

        false
      },
      FieldType::MultiSelect => {
        let old_field_type_option = old_field.get_type_option::<MultiSelectTypeOption>(field_type);
        let new_field_type_option = new_field.get_type_option::<MultiSelectTypeOption>(field_type);

        if let (Some(old_field_type_option), Some(new_field_type_option)) =
          (old_field_type_option, new_field_type_option)
        {
          return old_field_type_option.options.len() != new_field_type_option.options.len();
        }

        false
      },
      // All other FieldTypes
      _ => false,
    }
  }

  /// Called when a grouping field is updated.
  #[tracing::instrument(level = "debug", skip_all, err)]
  pub async fn v_group_by_field(&self, field_id: &str) -> FlowyResult<()> {
    if let Some(field) = self.delegate.get_field(field_id).await {
      tracing::trace!("create new group controller");

      let new_group_controller = new_group_controller(
        self.view_id.clone(),
        self.delegate.clone(),
        self.filter_controller.clone(),
        Some(field),
      )
      .await?;

      if let Some(controller) = &new_group_controller {
        let new_groups = controller
          .get_all_groups()
          .into_iter()
          .map(|group| GroupPB::from(group.clone()))
          .collect();

        let changeset = GroupChangesPB {
          view_id: self.view_id.clone(),
          initial_groups: new_groups,
          ..Default::default()
        };

        debug_assert!(!changeset.is_empty());
        if !changeset.is_empty() {
          send_notification(&changeset.view_id, DatabaseNotification::DidGroupByField)
            .payload(changeset)
            .send();
        }
      }

      *self.group_controller.write().await = new_group_controller;

      tracing::trace!("did write group_controller to cache");
    }

    Ok(())
  }

  pub async fn v_get_calendar_event(&self, row_id: RowId) -> Option<CalendarEventPB> {
    let layout_ty = DatabaseLayout::Calendar;
    let calendar_setting = self.v_get_layout_settings(&layout_ty).await.calendar?;

    // Text
    let primary_field = self.delegate.get_primary_field().await?;
    let text_cell = get_cell_for_row(self.delegate.clone(), &primary_field.id, &row_id).await?;

    // Date
    let date_field = self.delegate.get_field(&calendar_setting.field_id).await?;

    let date_cell = get_cell_for_row(self.delegate.clone(), &date_field.id, &row_id).await?;
    let title = text_cell
      .into_text_field_cell_data()
      .unwrap_or_default()
      .into();

    let timestamp = date_cell
      .into_date_field_cell_data()
      .unwrap_or_default()
      .timestamp
      .unwrap_or_default();

    let (_, row_detail) = self.delegate.get_row_detail(&self.view_id, &row_id).await?;
    Some(CalendarEventPB {
      row_meta: RowMetaPB::from(row_detail.as_ref().clone()),
      date_field_id: date_field.id.clone(),
      title,
      timestamp,
      is_scheduled: timestamp != 0,
    })
  }

  pub async fn v_get_all_calendar_events(&self) -> Option<Vec<CalendarEventPB>> {
    let layout_ty = DatabaseLayout::Calendar;
    let calendar_setting = match self.v_get_layout_settings(&layout_ty).await.calendar {
      None => {
        // When create a new calendar view, the calendar setting should be created
        tracing::error!(
          "Calendar layout setting not found in database view:{}",
          self.view_id
        );
        return None;
      },
      Some(calendar_setting) => calendar_setting,
    };

    // Text
    let primary_field = self.delegate.get_primary_field().await?;
    let text_cells =
      get_cells_for_field(self.delegate.clone(), &self.view_id, &primary_field.id).await;

    // Date
    let timestamp_by_row_id = get_cells_for_field(
      self.delegate.clone(),
      &self.view_id,
      &calendar_setting.field_id,
    )
    .await
    .into_iter()
    .map(|date_cell| {
      let row_id = date_cell.row_id.clone();

      // timestamp
      let timestamp = date_cell
        .into_date_field_cell_data()
        .map(|date_cell_data| date_cell_data.timestamp.unwrap_or_default())
        .unwrap_or_default();

      (row_id, timestamp)
    })
    .collect::<HashMap<RowId, i64>>();

    let mut events: Vec<CalendarEventPB> = vec![];
    for text_cell in text_cells {
      let row_id = text_cell.row_id.clone();
      let timestamp = timestamp_by_row_id
        .get(&row_id)
        .cloned()
        .unwrap_or_default();

      let title = text_cell
        .into_text_field_cell_data()
        .unwrap_or_default()
        .into();

      let (_, row_detail) = self.delegate.get_row_detail(&self.view_id, &row_id).await?;
      let event = CalendarEventPB {
        row_meta: RowMetaPB::from(row_detail.as_ref().clone()),
        date_field_id: calendar_setting.field_id.clone(),
        title,
        timestamp,
        is_scheduled: timestamp != 0,
      };
      events.push(event);
    }
    Some(events)
  }

  pub async fn v_get_layout_type(&self) -> DatabaseLayout {
    self.delegate.get_layout_for_view(&self.view_id).await
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_update_layout_type(&self, new_layout_type: DatabaseLayout) -> FlowyResult<()> {
    self
      .delegate
      .update_layout_type(&self.view_id, &new_layout_type)
      .await;

    // using the {} brackets to denote the lifetime of the resolver. Because the DatabaseLayoutDepsResolver
    // is not sync and send, so we can't pass it to the async block.
    {
      let resolver = DatabaseLayoutDepsResolver::new(self.delegate.get_database(), new_layout_type);
      resolver
        .resolve_deps_when_update_layout_type(&self.view_id)
        .await;
    }

    // initialize the group controller if the current layout support grouping
    *self.group_controller.write().await = new_group_controller(
      self.view_id.clone(),
      self.delegate.clone(),
      self.filter_controller.clone(),
      None,
    )
    .await?;

    let payload = DatabaseLayoutMetaPB {
      view_id: self.view_id.clone(),
      layout: new_layout_type.into(),
    };
    send_notification(&self.view_id, DatabaseNotification::DidUpdateDatabaseLayout)
      .payload(payload)
      .send();

    Ok(())
  }

  pub async fn handle_row_event(&self, event: Cow<'_, DatabaseRowEvent>) {
    let changeset = match event.into_owned() {
      DatabaseRowEvent::InsertRow(row) => RowsChangePB::from_insert(row.into()),
      DatabaseRowEvent::UpdateRow(row) => RowsChangePB::from_update(row.into()),
      DatabaseRowEvent::DeleteRow(row_id) => RowsChangePB::from_delete(row_id.into_inner()),
      DatabaseRowEvent::Move {
        deleted_row_id,
        inserted_row,
      } => RowsChangePB::from_move(vec![deleted_row_id.into_inner()], vec![inserted_row.into()]),
    };

    send_notification(&self.view_id, DatabaseNotification::DidUpdateRow)
      .payload(changeset)
      .send();
  }

  pub async fn v_get_field_settings(&self, field_ids: &[String]) -> HashMap<String, FieldSettings> {
    self
      .delegate
      .get_field_settings(&self.view_id, field_ids)
      .await
  }

  pub async fn v_update_field_settings(&self, params: FieldSettingsChangesetPB) -> FlowyResult<()> {
    self.delegate.update_field_settings(params).await;
    Ok(())
  }

  async fn mut_group_controller<F, T>(&self, f: F) -> Option<T>
  where
    F: FnOnce(&mut Box<dyn GroupController>, Field) -> FlowyResult<T>,
  {
    let group_field_id = self
      .group_controller
      .read()
      .await
      .as_ref()
      .map(|controller| controller.get_grouping_field_id().to_owned())?;
    let field = self.delegate.get_field(&group_field_id).await?;
    let mut write_guard = self.group_controller.write().await;
    if let Some(group_controller) = &mut *write_guard {
      f(group_controller, field).ok()
    } else {
      None
    }
  }

  async fn gen_did_update_row_view_tasks(&self, row_id: RowId, field_id: Option<String>) {
    let weak_filter_controller = Arc::downgrade(&self.filter_controller);
    let weak_sort_controller = Arc::downgrade(&self.sort_controller);
    let weak_calculations_controller = Arc::downgrade(&self.calculations_controller);
    tokio::spawn(async move {
      if let Some(filter_controller) = weak_filter_controller.upgrade() {
        filter_controller
          .did_receive_row_changed(row_id.clone())
          .await;
      }
      if let Some(sort_controller) = weak_sort_controller.upgrade() {
        sort_controller
          .read()
          .await
          .did_receive_row_changed(row_id.clone())
          .await;
      }

      if let Some(calculations_controller) = weak_calculations_controller.upgrade() {
        if let Some(field_id) = field_id {
          calculations_controller
            .did_receive_cell_changed(field_id)
            .await;
        }
      }
    });
  }

  async fn gen_did_create_row_view_tasks(&self, preliminary_index: u32, row: Row) {
    let weak_sort_controller = Arc::downgrade(&self.sort_controller);
    let weak_calculations_controller = Arc::downgrade(&self.calculations_controller);
    tokio::spawn(async move {
      if let Some(sort_controller) = weak_sort_controller.upgrade() {
        sort_controller
          .read()
          .await
          .did_create_row(preliminary_index, &row)
          .await;
      }

      if let Some(calculations_controller) = weak_calculations_controller.upgrade() {
        calculations_controller
          .did_receive_row_changed(row.clone())
          .await;
      }
    });
  }
}

async fn handle_mut_group_result(view_id: &str, result: Option<DidMoveGroupRowResult>) {
  if let Some(result) = result {
    if let Some(deleted_group) = result.deleted_group {
      trace!("Delete group after moving the row: {:?}", deleted_group);
      let payload = GroupChangesPB {
        view_id: view_id.to_string(),
        deleted_groups: vec![deleted_group.group_id],
        ..Default::default()
      };
      notify_did_update_num_of_groups(view_id, payload).await;
    }
    for changeset in result.row_changesets {
      trace!("[RowOrder]: group row changeset: {:?}", changeset);
      notify_did_update_group_rows(changeset).await;
    }
  }
}
