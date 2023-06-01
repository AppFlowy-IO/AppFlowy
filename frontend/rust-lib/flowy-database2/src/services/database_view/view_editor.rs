use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::{gen_database_filter_id, gen_database_sort_id};
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cells, Row, RowCell, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting, RowOrder};
use tokio::sync::{broadcast, RwLock};

use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;

use crate::entities::{
  CalendarEventPB, DatabaseLayoutMetaPB, DatabaseLayoutSettingPB, DeleteFilterParams,
  DeleteGroupParams, DeleteSortParams, FieldType, GroupChangesPB, GroupPB, GroupRowsNotificationPB,
  InsertedRowPB, LayoutSettingParams, RowPB, RowsChangePB, SortChangesetNotificationPB, SortPB,
  UpdateFilterParams, UpdateSortParams,
};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::CellCache;
use crate::services::database::{database_view_setting_pb_from_view, DatabaseRowEvent, UpdatedRow};
use crate::services::database_view::view_filter::make_filter_controller;
use crate::services::database_view::view_group::{
  get_cell_for_row, get_cells_for_field, new_group_controller, new_group_controller_with_field,
};
use crate::services::database_view::view_sort::make_sort_controller;
use crate::services::database_view::{
  notify_did_update_filter, notify_did_update_group_rows, notify_did_update_num_of_groups,
  notify_did_update_setting, notify_did_update_sort, DatabaseViewChangedNotifier,
  DatabaseViewChangedReceiverRunner,
};
use crate::services::field::{DateTypeOption, TypeOptionCellDataHandler};
use crate::services::filter::{
  Filter, FilterChangeset, FilterController, FilterType, UpdatedFilterType,
};
use crate::services::group::{
  GroupController, GroupSetting, GroupSettingChangeset, MoveGroupRowContext, RowChangeset,
};
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::{DeletedSortType, Sort, SortChangeset, SortController, SortType};

pub trait DatabaseViewData: Send + Sync + 'static {
  fn get_view(&self, view_id: &str) -> Fut<Option<DatabaseView>>;
  /// If the field_ids is None, then it will return all the field revisions
  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>>;

  /// Returns the field with the field_id
  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>>;

  fn create_field(
    &self,
    view_id: &str,
    name: &str,
    field_type: FieldType,
    type_option_data: TypeOptionData,
  ) -> Fut<Field>;

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>>;

  /// Returns the index of the row with row_id
  fn index_of_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<usize>>;

  /// Returns the `index` and `RowRevision` with row_id
  fn get_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<(usize, Arc<Row>)>>;

  /// Returns all the rows in the view
  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>>;

  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>>;

  fn get_cell_in_row(&self, field_id: &str, row_id: &RowId) -> Fut<Arc<RowCell>>;

  fn get_layout_for_view(&self, view_id: &str) -> DatabaseLayout;

  fn get_group_setting(&self, view_id: &str) -> Vec<GroupSetting>;

  fn insert_group_setting(&self, view_id: &str, setting: GroupSetting);

  fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Sort>;

  fn insert_sort(&self, view_id: &str, sort: Sort);

  fn remove_sort(&self, view_id: &str, sort_id: &str);

  fn get_all_sorts(&self, view_id: &str) -> Vec<Sort>;

  fn remove_all_sorts(&self, view_id: &str);

  fn get_all_filters(&self, view_id: &str) -> Vec<Arc<Filter>>;

  fn delete_filter(&self, view_id: &str, filter_id: &str);

  fn insert_filter(&self, view_id: &str, filter: Filter);

  fn get_filter(&self, view_id: &str, filter_id: &str) -> Option<Filter>;

  fn get_filter_by_field_id(&self, view_id: &str, field_id: &str) -> Option<Filter>;

  fn get_layout_setting(&self, view_id: &str, layout_ty: &DatabaseLayout) -> Option<LayoutSetting>;

  fn insert_layout_setting(
    &self,
    view_id: &str,
    layout_ty: &DatabaseLayout,
    layout_setting: LayoutSetting,
  );

  /// Return the database layout type for the view with given view_id
  /// The default layout type is [DatabaseLayout::Grid]
  fn get_layout_type(&self, view_id: &str) -> DatabaseLayout;

  fn update_layout_type(&self, view_id: &str, layout_type: &DatabaseLayout);

  /// Returns a `TaskDispatcher` used to poll a `Task`
  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>>;

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>>;
}

pub struct DatabaseViewEditor {
  pub view_id: String,
  delegate: Arc<dyn DatabaseViewData>,
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
    delegate: Arc<dyn DatabaseViewData>,
    cell_cache: CellCache,
  ) -> FlowyResult<Self> {
    let (notifier, _) = broadcast::channel(100);
    tokio::spawn(DatabaseViewChangedReceiverRunner(Some(notifier.subscribe())).run());
    let group_controller = new_group_controller(view_id.clone(), delegate.clone()).await?;
    let group_controller = Arc::new(RwLock::new(group_controller));

    let filter_controller = make_filter_controller(
      &view_id,
      delegate.clone(),
      notifier.clone(),
      cell_cache.clone(),
    )
    .await;

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

  pub async fn get_view(&self) -> Option<DatabaseView> {
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

  pub async fn v_did_create_row(&self, row: &Row, group_id: &Option<String>, index: usize) {
    // Send the group notification if the current view has groups
    match group_id.as_ref() {
      None => {
        let row = InsertedRowPB::from(row).with_index(index as i32);
        let changes = RowsChangePB::from_insert(self.view_id.clone(), row);
        send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
          .payload(changes)
          .send();
      },
      Some(group_id) => {
        self
          .mut_group_controller(|group_controller, _| {
            group_controller.did_create_row(row, group_id);
            Ok(())
          })
          .await;

        let inserted_row = InsertedRowPB {
          row: RowPB::from(row),
          index: Some(index as i32),
          is_new: true,
        };
        let changeset = GroupRowsNotificationPB::insert(group_id.clone(), vec![inserted_row]);
        notify_did_update_group_rows(changeset).await;
      },
    }
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_did_delete_row(&self, row: &Row) {
    // Send the group notification if the current view has groups;
    let result = self
      .mut_group_controller(|group_controller, field| {
        group_controller.did_delete_delete_row(row, &field)
      })
      .await;

    if let Some(result) = result {
      tracing::trace!("Delete row in view changeset: {:?}", result.row_changesets);
      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }
    let changes = RowsChangePB::from_delete(self.view_id.clone(), row.id.clone().into_inner());
    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changes)
      .send();
  }

  /// Notify the view that the row has been updated. If the view has groups,
  /// send the group notification with [GroupRowsNotificationPB]. Otherwise,
  /// send the view notification with [RowsChangePB]
  pub async fn v_did_update_row(&self, old_row: &Option<Row>, row: &Row, field_id: &str) {
    let result = self
      .mut_group_controller(|group_controller, field| {
        Ok(group_controller.did_update_group_row(old_row, row, &field))
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
    } else {
      let update_row = UpdatedRow {
        row: RowOrder::from(row),
        field_ids: vec![field_id.to_string()],
      };
      let changeset = RowsChangePB::from_update(self.view_id.clone(), update_row.into());
      send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
        .payload(changeset)
        .send();
    }

    // Each row update will trigger a filter and sort operation. We don't want
    // to block the main thread, so we spawn a new task to do the work.
    let row_id = row.id.clone();
    let weak_filter_controller = Arc::downgrade(&self.filter_controller);
    let weak_sort_controller = Arc::downgrade(&self.sort_controller);
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
          .did_receive_row_changed(row_id)
          .await;
      }
    });
  }

  pub async fn v_filter_rows(&self, rows: &mut Vec<Arc<Row>>) {
    self.filter_controller.filter_rows(rows).await
  }

  pub async fn v_sort_rows(&self, rows: &mut Vec<Arc<Row>>) {
    self.sort_controller.write().await.sort_rows(rows).await
  }

  pub async fn v_get_rows(&self) -> Vec<Arc<Row>> {
    let mut rows = self.delegate.get_rows(&self.view_id).await;
    self.v_filter_rows(&mut rows).await;
    self.v_sort_rows(&mut rows).await;
    rows
  }

  pub async fn v_move_group_row(
    &self,
    row: &Row,
    row_changeset: &mut RowChangeset,
    to_group_id: &str,
    to_row_id: Option<RowId>,
  ) {
    let result = self
      .mut_group_controller(|group_controller, field| {
        let move_row_context = MoveGroupRowContext {
          row,
          row_changeset,
          field: field.as_ref(),
          to_group_id,
          to_row_id,
        };
        group_controller.move_group_row(move_row_context)
      })
      .await;

    if let Some(result) = result {
      if let Some(delete_group) = result.deleted_group {
        tracing::trace!("Delete group after moving the row: {:?}", delete_group);
        let mut changes = GroupChangesPB {
          view_id: self.view_id.clone(),
          ..Default::default()
        };
        changes.deleted_groups.push(delete_group.group_id);
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
      .groups()
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
      None => Err(FlowyError::record_not_found().context("Can't find the group")),
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
      self.v_update_grouping_field(field_id).await?;

      if let Some(view) = self.delegate.get_view(&self.view_id).await {
        let setting = database_view_setting_pb_from_view(view);
        notify_did_update_setting(&self.view_id, setting).await;
      }
    }
    Ok(())
  }

  pub async fn v_delete_group(&self, _params: DeleteGroupParams) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn update_group_setting(&self, changeset: GroupSettingChangeset) -> FlowyResult<()> {
    self
      .mut_group_controller(|group_controller, _| {
        group_controller.apply_group_setting_changeset(changeset)
      })
      .await;
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
      DatabaseLayout::Board => {},
      DatabaseLayout::Calendar => {
        if let Some(value) = self.delegate.get_layout_setting(&self.view_id, layout_ty) {
          let calendar_setting = CalendarLayoutSetting::from(value);
          // Check the field exist or not
          if let Some(field) = self.delegate.get_field(&calendar_setting.field_id).await {
            let field_type = FieldType::from(field.field_type);

            // Check the type of field is Datetime or not
            if field_type == FieldType::DateTime {
              layout_setting.calendar = Some(calendar_setting);
            }
          }
        }
      },
    }

    layout_setting
  }

  /// Update the calendar settings and send the notification to refresh the UI
  pub async fn v_set_layout_settings(&self, params: LayoutSettingParams) -> FlowyResult<()> {
    // Maybe it needs no send notification to refresh the UI
    if let Some(new_calendar_setting) = params.calendar {
      if let Some(field) = self
        .delegate
        .get_field(&new_calendar_setting.field_id)
        .await
      {
        let field_type = FieldType::from(field.field_type);
        if field_type != FieldType::DateTime {
          return Err(FlowyError::unexpect_calendar_field_type());
        }

        let old_calender_setting = self
          .v_get_layout_settings(&params.layout_type)
          .await
          .calendar;

        self.delegate.insert_layout_setting(
          &self.view_id,
          &params.layout_type,
          new_calendar_setting.clone().into(),
        );
        let new_field_id = new_calendar_setting.field_id.clone();
        let layout_setting_pb: DatabaseLayoutSettingPB = LayoutSettingParams {
          layout_type: params.layout_type,
          calendar: Some(new_calendar_setting),
        }
        .into();

        if let Some(old_calendar_setting) = old_calender_setting {
          // compare the new layout field id is equal to old layout field id
          // if not equal, send the  DidSetNewLayoutField notification
          // if equal, send the  DidUpdateLayoutSettings notification
          if old_calendar_setting.field_id != new_field_id {
            send_notification(&self.view_id, DatabaseNotification::DidSetNewLayoutField)
              .payload(layout_setting_pb)
              .send();
          } else {
            send_notification(&self.view_id, DatabaseNotification::DidUpdateLayoutSettings)
              .payload(layout_setting_pb)
              .send();
          }
        }
      }
    }

    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn v_did_update_field_type_option(
    &self,
    field_id: &str,
    old_field: &Field,
  ) -> FlowyResult<()> {
    if let Some(field) = self.delegate.get_field(field_id).await {
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
        let _ = tokio::spawn(async move {
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
  pub async fn v_update_grouping_field(&self, field_id: &str) -> FlowyResult<()> {
    if let Some(field) = self.delegate.get_field(field_id).await {
      let new_group_controller =
        new_group_controller_with_field(self.view_id.clone(), self.delegate.clone(), field).await?;

      let new_groups = new_group_controller
        .groups()
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

    Some(CalendarEventPB {
      row_id: row_id.into_inner(),
      date_field_id: date_field.id.clone(),
      title,
      timestamp,
    })
  }

  pub async fn v_get_all_calendar_events(&self) -> Option<Vec<CalendarEventPB>> {
    let layout_ty = DatabaseLayout::Calendar;
    let calendar_setting = self.v_get_layout_settings(&layout_ty).await.calendar?;

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

      let event = CalendarEventPB {
        row_id: row_id.into_inner(),
        date_field_id: calendar_setting.field_id.clone(),
        title,
        timestamp,
      };
      events.push(event);
    }
    Some(events)
  }

  #[tracing::instrument(level = "trace", skip_all)]
  pub async fn v_update_layout_type(&self, layout_type: DatabaseLayout) -> FlowyResult<()> {
    self
      .delegate
      .update_layout_type(&self.view_id, &layout_type);

    // Update the layout type in the database might add a new field to the database. If the new
    // layout type is a calendar and there is not date field in the database, it will add a new
    // date field to the database and create the corresponding layout setting.
    //
    let fields = self.delegate.get_fields(&self.view_id, None).await;
    let date_field_id = match fields
      .into_iter()
      .find(|field| FieldType::from(field.field_type) == FieldType::DateTime)
    {
      None => {
        tracing::trace!("Create a new date field after layout type change");
        let default_date_type_option = DateTypeOption::default();
        let field = self
          .delegate
          .create_field(
            &self.view_id,
            "Date",
            FieldType::DateTime,
            default_date_type_option.into(),
          )
          .await;
        field.id
      },
      Some(date_field) => date_field.id.clone(),
    };

    let layout_setting = self.v_get_layout_settings(&layout_type).await;
    match layout_type {
      DatabaseLayout::Grid => {},
      DatabaseLayout::Board => {},
      DatabaseLayout::Calendar => {
        if layout_setting.calendar.is_none() {
          let layout_setting = CalendarLayoutSetting::new(date_field_id.clone());
          self
            .v_set_layout_settings(LayoutSettingParams {
              layout_type,
              calendar: Some(layout_setting),
            })
            .await?;
        }
      },
    }

    let payload = DatabaseLayoutMetaPB {
      view_id: self.view_id.clone(),
      layout: layout_type.into(),
    };
    send_notification(&self.view_id, DatabaseNotification::DidUpdateDatabaseLayout)
      .payload(payload)
      .send();

    Ok(())
  }

  pub async fn handle_row_event(&self, event: Cow<'_, DatabaseRowEvent>) {
    let changeset = match event.into_owned() {
      DatabaseRowEvent::InsertRow(row) => {
        RowsChangePB::from_insert(self.view_id.clone(), row.into())
      },
      DatabaseRowEvent::UpdateRow(row) => {
        RowsChangePB::from_update(self.view_id.clone(), row.into())
      },
      DatabaseRowEvent::DeleteRow(row_id) => {
        RowsChangePB::from_delete(self.view_id.clone(), row_id.into_inner())
      },
      DatabaseRowEvent::Move {
        deleted_row_id,
        inserted_row,
      } => RowsChangePB::from_move(
        self.view_id.clone(),
        vec![deleted_row_id.into_inner()],
        vec![inserted_row.into()],
      ),
    };

    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changeset)
      .send();
  }

  async fn mut_group_controller<F, T>(&self, f: F) -> Option<T>
  where
    F: FnOnce(&mut Box<dyn GroupController>, Arc<Field>) -> FlowyResult<T>,
  {
    let group_field_id = self
      .group_controller
      .read()
      .await
      .as_ref()
      .map(|group| group.field_id().to_owned())?;
    let field = self.delegate.get_field(&group_field_id).await?;

    let mut write_guard = self.group_controller.write().await;
    if let Some(group_controller) = &mut *write_guard {
      f(group_controller, field).ok()
    } else {
      None
    }
  }
}
