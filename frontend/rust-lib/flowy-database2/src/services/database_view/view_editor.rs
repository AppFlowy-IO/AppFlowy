use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::{gen_database_calculation_id, gen_database_sort_id, gen_row_id};
use collab_database::fields::Field;
use collab_database::rows::{Cells, Row, RowDetail, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView};
use lib_infra::util::timestamp;
use tokio::sync::{broadcast, RwLock};
use tracing::instrument;

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::af_spawn;

use crate::entities::{
  CalendarEventPB, CreateRowParams, CreateRowPayloadPB, DatabaseLayoutMetaPB,
  DatabaseLayoutSettingPB, DeleteSortPayloadPB, FieldSettingsChangesetPB, FieldType,
  GroupChangesPB, GroupPB, LayoutSettingChangeset, LayoutSettingParams,
  RemoveCalculationChangesetPB, ReorderSortPayloadPB, RowMetaPB, RowsChangePB,
  SortChangesetNotificationPB, SortPB, UpdateCalculationChangesetPB, UpdateSortPayloadPB,
};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::calculations::{Calculation, CalculationChangeset, CalculationsController};
use crate::services::cell::{CellBuilder, CellCache};
use crate::services::database::{database_view_setting_pb_from_view, DatabaseRowEvent, UpdatedRow};
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
use crate::services::field_settings::FieldSettings;
use crate::services::filter::{Filter, FilterChangeset, FilterController};
use crate::services::group::{GroupChangeset, GroupController, MoveGroupRowContext, RowChangeset};
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::{Sort, SortChangeset, SortController};

use super::notify_did_update_calculation;
use super::view_calculations::make_calculations_controller;

pub struct DatabaseViewEditor {
  database_id: String,
  pub view_id: String,
  delegate: Arc<dyn DatabaseViewOperation>,
  group_controller: Arc<RwLock<Option<Box<dyn GroupController>>>>,
  filter_controller: Arc<FilterController>,
  sort_controller: Arc<RwLock<SortController>>,
  calculations_controller: Arc<CalculationsController>,
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
    af_spawn(DatabaseViewChangedReceiverRunner(Some(notifier.subscribe())).run());

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
      notifier,
    })
  }

  pub async fn close(&self) {
    self.sort_controller.write().await.close().await;
    self.filter_controller.close().await;
    self.calculations_controller.close().await;
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

  pub async fn v_did_create_row(&self, row_detail: &RowDetail, index: usize) {
    // Send the group notification if the current view has groups
    if let Some(controller) = self.group_controller.write().await.as_mut() {
      let mut row_details = vec![Arc::new(row_detail.clone())];
      self.v_filter_rows(&mut row_details).await;

      if let Some(row_detail) = row_details.pop() {
        let changesets = controller.did_create_row(&row_detail, index);

        for changeset in changesets {
          notify_did_update_group_rows(changeset).await;
        }
      }
    }

    self
      .gen_did_create_row_view_tasks(index, row_detail.clone())
      .await;
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_did_delete_row(&self, row: &Row) {
    let deleted_row = row.clone();

    // Send the group notification if the current view has groups;
    let result = self
      .mut_group_controller(|group_controller, _| group_controller.did_delete_row(row))
      .await;

    if let Some(result) = result {
      tracing::trace!("Delete row in view changeset: {:?}", result);
      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
      if let Some(deleted_group) = result.deleted_group {
        let payload = GroupChangesPB {
          view_id: self.view_id.clone(),
          deleted_groups: vec![deleted_group.group_id],
          ..Default::default()
        };
        notify_did_update_num_of_groups(&self.view_id, payload).await;
      }
    }
    let changes = RowsChangePB::from_delete(row.id.clone().into_inner());

    send_notification(&self.view_id, DatabaseNotification::DidUpdateRow)
      .payload(changes)
      .send();

    // Updating calculations for each of the Rows cells is a tedious task
    // Therefore we spawn a separate task for this
    let weak_calculations_controller = Arc::downgrade(&self.calculations_controller);
    af_spawn(async move {
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
  pub async fn v_did_update_row(
    &self,
    old_row: &Option<RowDetail>,
    row_detail: &RowDetail,
    field_id: Option<String>,
  ) {
    if let Some(controller) = self.group_controller.write().await.as_mut() {
      let field = self.delegate.get_field(controller.get_grouping_field_id());

      if let Some(field) = field {
        let mut row_details = vec![Arc::new(row_detail.clone())];
        self.v_filter_rows(&mut row_details).await;

        if let Some(row_detail) = row_details.pop() {
          let result = controller.did_update_group_row(old_row, &row_detail, &field);

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
    if let Some(field_id) = field_id {
      self
        .gen_did_update_row_view_tasks(row_detail.row.id.clone(), field_id)
        .await;
    }
  }

  pub async fn v_filter_rows(&self, row_details: &mut Vec<Arc<RowDetail>>) {
    self.filter_controller.filter_rows(row_details).await
  }

  pub async fn v_sort_rows(&self, row_details: &mut Vec<Arc<RowDetail>>) {
    self
      .sort_controller
      .write()
      .await
      .sort_rows(row_details)
      .await
  }

  #[instrument(level = "info", skip(self))]
  pub async fn v_get_rows(&self) -> Vec<Arc<RowDetail>> {
    let mut rows = self.delegate.get_rows(&self.view_id).await;
    self.v_filter_rows(&mut rows).await;
    self.v_sort_rows(&mut rows).await;
    rows
  }

  pub async fn v_move_group_row(
    &self,
    row_detail: &RowDetail,
    row_changeset: &mut RowChangeset,
    to_group_id: &str,
    to_row_id: Option<RowId>,
  ) {
    let result = self
      .mut_group_controller(|group_controller, field| {
        let move_row_context = MoveGroupRowContext {
          row_detail,
          row_changeset,
          field: &field,
          to_group_id,
          to_row_id,
        };
        group_controller.move_group_row(move_row_context)
      })
      .await;

    if let Some(result) = result {
      if let Some(delete_group) = result.deleted_group {
        tracing::trace!("Delete group after moving the row: {:?}", delete_group);
        let changes = GroupChangesPB {
          view_id: self.view_id.clone(),
          deleted_groups: vec![delete_group.group_id],
          ..Default::default()
        };
        notify_did_update_num_of_groups(&self.view_id, changes).await;
      }

      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }
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
    let is_grouping_field = self.is_grouping_field(field_id).await;
    if !is_grouping_field {
      self.v_group_by_field(field_id).await?;

      if let Some(view) = self.delegate.get_view(&self.view_id).await {
        let setting = database_view_setting_pb_from_view(view);
        notify_did_update_setting(&self.view_id, setting).await;
      }
    }
    Ok(())
  }

  pub async fn v_create_group(&self, name: &str) -> FlowyResult<()> {
    let mut old_field: Option<Field> = None;
    let result = if let Some(controller) = self.group_controller.write().await.as_mut() {
      let create_group_results = controller.create_group(name.to_string())?;
      old_field = self.delegate.get_field(controller.get_grouping_field_id());
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

    let old_field = self.delegate.get_field(controller.get_grouping_field_id());
    let (row_ids, type_option_data) = controller.delete_group(group_id)?;

    drop(group_controller);

    let mut changes = RowsChangePB::default();

    if let Some(field) = old_field {
      let deleted_rows = row_ids
        .iter()
        .filter_map(|row_id| self.delegate.remove_row(row_id))
        .map(|row| row.id.into_inner());

      changes.deleted_rows.extend(deleted_rows);

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
    let (old_field, updated_groups) =
      if let Some(controller) = self.group_controller.write().await.as_mut() {
        let old_field = self.delegate.get_field(controller.get_grouping_field_id());
        let (updated_groups, new_type_option) = controller.apply_group_changeset(&changeset)?;

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

  pub async fn v_get_all_sorts(&self) -> Vec<Sort> {
    self.delegate.get_all_sorts(&self.view_id)
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

    self.delegate.insert_sort(&self.view_id, sort.clone());

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
      .move_sort(&self.view_id, &params.from_sort_id, &params.to_sort_id);

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

    self.delegate.remove_sort(&self.view_id, &params.sort_id);
    notify_did_update_sort(notification).await;

    Ok(())
  }

  pub async fn v_delete_all_sorts(&self) -> FlowyResult<()> {
    let all_sorts = self.v_get_all_sorts().await;
    self.sort_controller.write().await.delete_all_sorts().await;

    self.delegate.remove_all_sorts(&self.view_id);
    let mut notification = SortChangesetNotificationPB::new(self.view_id.clone());
    notification.delete_sorts = all_sorts.into_iter().map(SortPB::from).collect();
    notify_did_update_sort(notification).await;
    Ok(())
  }

  pub async fn v_get_all_calculations(&self) -> Vec<Arc<Calculation>> {
    self.delegate.get_all_calculations(&self.view_id)
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
            .update_calculation(&params.view_id, calculation);
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
      .remove_calculation(&params.view_id, &params.calculation_id);

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
    self.delegate.get_all_filters(&self.view_id)
  }

  pub async fn v_get_filter(&self, filter_id: &str) -> Option<Filter> {
    self.delegate.get_filter(&self.view_id, filter_id)
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
        if let Some(value) = self.delegate.get_layout_setting(&self.view_id, layout_ty) {
          layout_setting.board = Some(value.into());
        }
      },
      DatabaseLayout::Calendar => {
        if let Some(value) = self.delegate.get_layout_setting(&self.view_id, layout_ty) {
          let calendar_setting = CalendarLayoutSetting::from(value);
          // Check the field exist or not
          if let Some(field) = self.delegate.get_field(&calendar_setting.field_id) {
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

        self.delegate.insert_layout_setting(
          &self.view_id,
          &params.layout_type,
          layout_setting.clone().into(),
        );

        Some(DatabaseLayoutSettingPB::from_board(layout_setting))
      },
      DatabaseLayout::Calendar => {
        let layout_setting = params.calendar.unwrap();

        if let Some(field) = self.delegate.get_field(&layout_setting.field_id) {
          if FieldType::from(field.field_type) != FieldType::DateTime {
            return Err(FlowyError::unexpect_calendar_field_type());
          }

          self.delegate.insert_layout_setting(
            &self.view_id,
            &params.layout_type,
            layout_setting.clone().into(),
          );

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

    let sorts = self.delegate.get_all_sorts(&self.view_id);

    if let Some(sort) = sorts.iter().find(|sort| sort.field_id == deleted_field_id) {
      self.delegate.remove_sort(&self.view_id, &sort.id);
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

    if let Some(field) = self.delegate.get_field(field_id) {
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
    }

    // If the id of the grouping field is equal to the updated field's id, then we need to
    // update the group setting
    if self.is_grouping_field(field_id).await {
      self.v_group_by_field(field_id).await?;
    }

    Ok(())
  }

  /// Called when a grouping field is updated.
  #[tracing::instrument(level = "debug", skip_all, err)]
  pub async fn v_group_by_field(&self, field_id: &str) -> FlowyResult<()> {
    if let Some(field) = self.delegate.get_field(field_id) {
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
        tracing::trace!("notify did group by field1");

        debug_assert!(!changeset.is_empty());
        if !changeset.is_empty() {
          send_notification(&changeset.view_id, DatabaseNotification::DidGroupByField)
            .payload(changeset)
            .send();
        }
      }
      tracing::trace!("notify did group by field2");

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
    let date_field = self.delegate.get_field(&calendar_setting.field_id)?;

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

    let (_, row_detail) = self.delegate.get_row(&self.view_id, &row_id).await?;
    Some(CalendarEventPB {
      row_meta: RowMetaPB::from(row_detail.as_ref()),
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

      let (_, row_detail) = self.delegate.get_row(&self.view_id, &row_id).await?;
      let event = CalendarEventPB {
        row_meta: RowMetaPB::from(row_detail.as_ref()),
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
    self.delegate.get_layout_for_view(&self.view_id)
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_update_layout_type(&self, new_layout_type: DatabaseLayout) -> FlowyResult<()> {
    self
      .delegate
      .update_layout_type(&self.view_id, &new_layout_type);

    // using the {} brackets to denote the lifetime of the resolver. Because the DatabaseLayoutDepsResolver
    // is not sync and send, so we can't pass it to the async block.
    {
      let resolver = DatabaseLayoutDepsResolver::new(self.delegate.get_database(), new_layout_type);
      resolver.resolve_deps_when_update_layout_type(&self.view_id);
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
    self.delegate.get_field_settings(&self.view_id, field_ids)
  }

  pub async fn v_update_field_settings(&self, params: FieldSettingsChangesetPB) -> FlowyResult<()> {
    self.delegate.update_field_settings(params);

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
    let field = self.delegate.get_field(&group_field_id)?;
    let mut write_guard = self.group_controller.write().await;
    if let Some(group_controller) = &mut *write_guard {
      f(group_controller, field).ok()
    } else {
      None
    }
  }

  async fn gen_did_update_row_view_tasks(&self, row_id: RowId, field_id: String) {
    let weak_filter_controller = Arc::downgrade(&self.filter_controller);
    let weak_sort_controller = Arc::downgrade(&self.sort_controller);
    let weak_calculations_controller = Arc::downgrade(&self.calculations_controller);
    af_spawn(async move {
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
        calculations_controller
          .did_receive_cell_changed(field_id)
          .await;
      }
    });
  }

  async fn gen_did_create_row_view_tasks(&self, preliminary_index: usize, row_detail: RowDetail) {
    let weak_sort_controller = Arc::downgrade(&self.sort_controller);
    let weak_calculations_controller = Arc::downgrade(&self.calculations_controller);
    af_spawn(async move {
      if let Some(sort_controller) = weak_sort_controller.upgrade() {
        sort_controller
          .read()
          .await
          .did_create_row(preliminary_index, &row_detail)
          .await;
      }

      if let Some(calculations_controller) = weak_calculations_controller.upgrade() {
        calculations_controller
          .did_receive_row_changed(row_detail.row.clone())
          .await;
      }
    });
  }
}
