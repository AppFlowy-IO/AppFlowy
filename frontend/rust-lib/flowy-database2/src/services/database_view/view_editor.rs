use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::{gen_database_filter_id, gen_database_sort_id};
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cells, Row, RowDetail, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView};
use tokio::sync::{broadcast, RwLock};
use tracing::instrument;

use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::af_spawn;

use crate::entities::{
  CalendarEventPB, DatabaseLayoutMetaPB, DatabaseLayoutSettingPB, DeleteFilterParams,
  DeleteSortParams, FieldType, FieldVisibility, GroupChangesPB, GroupPB, InsertedRowPB,
  LayoutSettingChangeset, LayoutSettingParams, RowMetaPB, RowsChangePB,
  SortChangesetNotificationPB, SortPB, UpdateFilterParams, UpdateSortParams,
};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::CellCache;
use crate::services::database::{database_view_setting_pb_from_view, DatabaseRowEvent, UpdatedRow};
use crate::services::database_view::view_filter::make_filter_controller;
use crate::services::database_view::view_group::{
  get_cell_for_row, get_cells_for_field, new_group_controller, new_group_controller_with_field,
};
use crate::services::database_view::view_operation::DatabaseViewOperation;
use crate::services::database_view::view_sort::make_sort_controller;
use crate::services::database_view::{
  notify_did_update_filter, notify_did_update_group_rows, notify_did_update_num_of_groups,
  notify_did_update_setting, notify_did_update_sort, DatabaseLayoutDepsResolver,
  DatabaseViewChangedNotifier, DatabaseViewChangedReceiverRunner,
};
use crate::services::field_settings::FieldSettings;
use crate::services::filter::{
  Filter, FilterChangeset, FilterController, FilterType, UpdatedFilterType,
};
use crate::services::group::{GroupChangesets, GroupController, MoveGroupRowContext, RowChangeset};
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::{DeletedSortType, Sort, SortChangeset, SortController, SortType};

pub struct DatabaseViewEditor {
  pub view_id: String,
  delegate: Arc<dyn DatabaseViewOperation>,
  group_controller: Arc<RwLock<Option<Box<dyn GroupController>>>>,
  filter_controller: Arc<FilterController>,
  sort_controller: Arc<RwLock<SortController>>,
  pub notifier: DatabaseViewChangedNotifier,
}

impl Drop for DatabaseViewEditor {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl DatabaseViewEditor {
  pub async fn new(
    view_id: String,
    delegate: Arc<dyn DatabaseViewOperation>,
    cell_cache: CellCache,
  ) -> FlowyResult<Self> {
    let (notifier, _) = broadcast::channel(100);
    af_spawn(DatabaseViewChangedReceiverRunner(Some(notifier.subscribe())).run());
    // Group
    let group_controller = Arc::new(RwLock::new(
      new_group_controller(view_id.clone(), delegate.clone()).await?,
    ));

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

    Ok(Self {
      view_id,
      delegate,
      group_controller,
      filter_controller,
      sort_controller,
      notifier,
    })
  }

  pub async fn close(&self) {
    self.sort_controller.write().await.close().await;
    self.filter_controller.close().await;
  }

  pub async fn v_get_view(&self) -> Option<DatabaseView> {
    self.delegate.get_view(&self.view_id).await
  }

  pub async fn v_will_create_row(&self, cells: &mut Cells, group_id: &Option<String>) {
    if group_id.is_none() {
      return;
    }
    let group_id = group_id.as_ref().unwrap();
    let _ = self
      .mut_group_controller(|group_controller, field| {
        group_controller.will_create_row(cells, &field, group_id);
        Ok(())
      })
      .await;
  }

  pub async fn v_did_update_row_meta(&self, row_id: &RowId, row_detail: &RowDetail) {
    let update_row = UpdatedRow::new(row_id.as_str()).with_row_meta(row_detail.clone());
    let changeset = RowsChangePB::from_update(update_row.into());
    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changeset)
      .send();
  }

  pub async fn v_did_create_row(&self, row_detail: &RowDetail, index: usize) {
    // Send the group notification if the current view has groups
    if let Some(controller) = self.group_controller.write().await.as_mut() {
      let changesets = controller.did_create_row(row_detail, index);

      for changeset in changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }

    let inserted_row = InsertedRowPB {
      row_meta: RowMetaPB::from(row_detail),
      index: Some(index as i32),
      is_new: true,
    };
    let changes = RowsChangePB::from_insert(inserted_row);
    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changes)
      .send();
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_did_delete_row(&self, row: &Row) {
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
    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changes)
      .send();
  }

  /// Notify the view that the row has been updated. If the view has groups,
  /// send the group notification with [GroupRowsNotificationPB]. Otherwise,
  /// send the view notification with [RowsChangePB]
  pub async fn v_did_update_row(&self, old_row: &Option<RowDetail>, row_detail: &RowDetail) {
    let result = self
      .mut_group_controller(|group_controller, field| {
        Ok(group_controller.did_update_group_row(old_row, row_detail, &field))
      })
      .await;

    if let Some(Ok(result)) = result {
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

    // Each row update will trigger a filter and sort operation. We don't want
    // to block the main thread, so we spawn a new task to do the work.
    let row_id = row_detail.row.id.clone();
    let weak_filter_controller = Arc::downgrade(&self.filter_controller);
    let weak_sort_controller = Arc::downgrade(&self.sort_controller);
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
          .did_receive_row_changed(row_id)
          .await;
      }
    });
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
      Some(group_controller) => group_controller.field_id() == field_id,
      None => false,
    }
  }

  /// Called when the user changes the grouping field
  pub async fn v_initialize_new_group(&self, field_id: &str) -> FlowyResult<()> {
    let is_grouping_field = self.is_grouping_field(field_id).await;
    if !is_grouping_field {
      self.v_grouping_by_field(field_id).await?;

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
      old_field = self.delegate.get_field(controller.field_id());
      create_group_results
    } else {
      (None, None)
    };

    if let Some(old_field) = old_field {
      if let (Some(type_option_data), Some(payload)) = result {
        self
          .delegate
          .update_field(&self.view_id, type_option_data, old_field)
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

    let old_field = self.delegate.get_field(controller.field_id());
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
        self
          .delegate
          .update_field(&self.view_id, type_option, field)
          .await?;
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

  pub async fn v_update_group(&self, changeset: GroupChangesets) -> FlowyResult<()> {
    let mut type_option_data = TypeOptionData::new();
    let (old_field, updated_groups) = if let Some(controller) =
      self.group_controller.write().await.as_mut()
    {
      let old_field = self.delegate.get_field(controller.field_id());
      let (updated_groups, new_type_option) = controller.apply_group_changeset(&changeset).await?;
      type_option_data.extend(new_type_option);

      (old_field, updated_groups)
    } else {
      (None, vec![])
    };

    if let Some(old_field) = old_field {
      if !type_option_data.is_empty() {
        self
          .delegate
          .update_field(&self.view_id, type_option_data, old_field)
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
  pub async fn v_insert_sort(&self, params: UpdateSortParams) -> FlowyResult<Sort> {
    let is_exist = params.sort_id.is_some();
    let sort_id = match params.sort_id {
      None => gen_database_sort_id(),
      Some(sort_id) => sort_id,
    };

    let sort = Sort {
      id: sort_id,
      field_id: params.field_id.clone(),
      field_type: params.field_type,
      condition: params.condition,
    };
    let sort_type = SortType::from(&sort);
    let mut sort_controller = self.sort_controller.write().await;
    self.delegate.insert_sort(&self.view_id, sort.clone());
    let changeset = if is_exist {
      sort_controller
        .did_receive_changes(SortChangeset::from_update(sort_type))
        .await
    } else {
      sort_controller
        .did_receive_changes(SortChangeset::from_insert(sort_type))
        .await
    };
    drop(sort_controller);
    notify_did_update_sort(changeset).await;
    Ok(sort)
  }

  pub async fn v_delete_sort(&self, params: DeleteSortParams) -> FlowyResult<()> {
    let notification = self
      .sort_controller
      .write()
      .await
      .did_receive_changes(SortChangeset::from_delete(DeletedSortType::from(
        params.clone(),
      )))
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

  pub async fn v_get_all_filters(&self) -> Vec<Arc<Filter>> {
    self.delegate.get_all_filters(&self.view_id)
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_insert_filter(&self, params: UpdateFilterParams) -> FlowyResult<()> {
    let is_exist = params.filter_id.is_some();
    let filter_id = match params.filter_id {
      None => gen_database_filter_id(),
      Some(filter_id) => filter_id,
    };
    let filter = Filter {
      id: filter_id.clone(),
      field_id: params.field_id.clone(),
      field_type: params.field_type,
      condition: params.condition,
      content: params.content,
    };
    let filter_type = FilterType::from(&filter);
    let filter_controller = self.filter_controller.clone();
    let changeset = if is_exist {
      let old_filter_type = self
        .delegate
        .get_filter(&self.view_id, &filter.id)
        .map(|field| FilterType::from(&field));

      self.delegate.insert_filter(&self.view_id, filter);
      filter_controller
        .did_receive_changes(FilterChangeset::from_update(UpdatedFilterType::new(
          old_filter_type,
          filter_type,
        )))
        .await
    } else {
      self.delegate.insert_filter(&self.view_id, filter);
      filter_controller
        .did_receive_changes(FilterChangeset::from_insert(filter_type))
        .await
    };
    drop(filter_controller);

    if let Some(changeset) = changeset {
      notify_did_update_filter(changeset).await;
    }
    Ok(())
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_delete_filter(&self, params: DeleteFilterParams) -> FlowyResult<()> {
    let filter_type = params.filter_type;
    let changeset = self
      .filter_controller
      .did_receive_changes(FilterChangeset::from_delete(filter_type.clone()))
      .await;

    self
      .delegate
      .delete_filter(&self.view_id, &filter_type.filter_id);
    if changeset.is_some() {
      notify_did_update_filter(changeset.unwrap()).await;
    }
    Ok(())
  }

  pub async fn v_get_filter(&self, filter_id: &str) -> Option<Filter> {
    self.delegate.get_filter(&self.view_id, filter_id)
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

  /// Notifies the view's field type-option data is changed
  /// For the moment, only the groups will be generated after the type-option data changed. A
  /// [Field] has a property named type_options contains a list of type-option data.
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn v_did_update_field_type_option(&self, old_field: &Field) -> FlowyResult<()> {
    let field_id = &old_field.id;
    // If the id of the grouping field is equal to the updated field's id, then we need to
    // update the group setting
    if self.is_grouping_field(field_id).await {
      self.v_grouping_by_field(field_id).await?;
    }

    if let Some(field) = self.delegate.get_field(field_id) {
      self
        .sort_controller
        .read()
        .await
        .did_update_field_type_option(&field)
        .await;

      self
        .mut_group_controller(|group_controller, _| {
          group_controller.did_update_field_type_option(&field);
          Ok(())
        })
        .await;

      if let Some(filter) = self
        .delegate
        .get_filter_by_field_id(&self.view_id, field_id)
      {
        let mut old = FilterType::from(&filter);
        old.field_type = FieldType::from(old_field.field_type);
        let new = FilterType::from(&filter);
        let filter_type = UpdatedFilterType::new(Some(old), new);
        let filter_changeset = FilterChangeset::from_update(filter_type);
        let filter_controller = self.filter_controller.clone();
        af_spawn(async move {
          if let Some(notification) = filter_controller
            .did_receive_changes(filter_changeset)
            .await
          {
            notify_did_update_filter(notification).await;
          }
        });
      }
    }
    Ok(())
  }

  /// Called when a grouping field is updated.
  #[tracing::instrument(level = "debug", skip_all, err)]
  pub async fn v_grouping_by_field(&self, field_id: &str) -> FlowyResult<()> {
    if let Some(field) = self.delegate.get_field(field_id) {
      let new_group_controller = new_group_controller_with_field(
        self.view_id.clone(),
        self.delegate.clone(),
        Arc::new(field),
      )
      .await?;

      let new_groups = new_group_controller
        .get_all_groups()
        .into_iter()
        .map(|group| GroupPB::from(group.clone()))
        .collect();

      *self.group_controller.write().await = Some(new_group_controller);
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
    *self.group_controller.write().await =
      new_group_controller(self.view_id.clone(), self.delegate.clone()).await?;

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

    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changeset)
      .send();
  }

  pub async fn v_get_field_settings(&self, field_ids: &[String]) -> HashMap<String, FieldSettings> {
    self.delegate.get_field_settings(&self.view_id, field_ids)
  }

  // pub async fn v_get_all_field_settings(&self) -> HashMap<String, FieldSettings> {
  //   self.delegate.get_all_field_settings(&self.view_id)
  // }

  pub async fn v_update_field_settings(
    &self,
    view_id: &str,
    field_id: &str,
    visibility: Option<FieldVisibility>,
    width: Option<i32>,
  ) -> FlowyResult<()> {
    self
      .delegate
      .update_field_settings(view_id, field_id, visibility, width);

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
      .map(|group| group.field_id().to_owned())?;
    let field = self.delegate.get_field(&group_field_id)?;
    let mut write_guard = self.group_controller.write().await;
    if let Some(group_controller) = &mut *write_guard {
      f(group_controller, field).ok()
    } else {
      None
    }
  }
}
