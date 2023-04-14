use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::{gen_database_filter_id, gen_database_sort_id};
use collab_database::fields::Field;
use collab_database::rows::{Cells, Row, RowCell, RowId};
use collab_database::views::{DatabaseLayout, DatabaseView, LayoutSetting};
use tokio::sync::{broadcast, RwLock};

use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;

use crate::entities::{
  AlterFilterParams, AlterSortParams, CalendarEventPB, DeleteFilterParams, DeleteGroupParams,
  DeleteSortParams, FieldType, GroupChangesetPB, GroupPB, GroupRowsNotificationPB,
  InsertGroupParams, InsertedGroupPB, InsertedRowPB, LayoutSettingPB, LayoutSettingParams,
  MoveGroupParams, RowPB, RowsChangesetPB, SortChangesetNotificationPB, SortPB,
};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::cell::CellCache;
use crate::services::database::{database_view_setting_pb_from_view, DatabaseRowEvent};
use crate::services::database_view::view_filter::make_filter_controller;
use crate::services::database_view::view_group::{
  get_cell_for_row, get_cells_for_field, new_group_controller, new_group_controller_with_field,
};
use crate::services::database_view::view_sort::make_sort_controller;
use crate::services::database_view::{
  notify_did_update_filter, notify_did_update_group_rows, notify_did_update_groups,
  notify_did_update_setting, notify_did_update_sort, DatabaseViewChangedNotifier,
  DatabaseViewChangedReceiverRunner,
};
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::filter::{
  Filter, FilterChangeset, FilterController, FilterType, UpdatedFilterType,
};
use crate::services::group::{GroupController, GroupSetting, MoveGroupRowContext, RowChangeset};
use crate::services::setting::CalendarLayoutSetting;
use crate::services::sort::{DeletedSortType, Sort, SortChangeset, SortController, SortType};

pub trait DatabaseViewData: Send + Sync + 'static {
  fn get_view_setting(&self, view_id: &str) -> Fut<Option<DatabaseView>>;
  /// If the field_ids is None, then it will return all the field revisions
  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>>;

  /// Returns the field with the field_id
  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>>;

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>>;

  /// Returns the index of the row with row_id
  fn index_of_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<usize>>;

  /// Returns the `index` and `RowRevision` with row_id
  fn get_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<(usize, Arc<Row>)>>;

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>>;

  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>>;

  fn get_cell_in_row(&self, field_id: &str, row_id: RowId) -> Fut<Option<Arc<RowCell>>>;

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

  fn insert_layout_setting(&self, view_id: &str, layout_setting: LayoutSetting);

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
  group_controller: Arc<RwLock<Box<dyn GroupController>>>,
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
      None => {},
      Some(group_id) => {
        self
          .group_controller
          .write()
          .await
          .did_create_row(row, group_id);
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
  }

  pub async fn v_did_update_row(&self, old_row: &Option<Row>, row: &Row) {
    let result = self
      .mut_group_controller(|group_controller, field| {
        Ok(group_controller.did_update_group_row(old_row, row, &field))
      })
      .await;

    if let Some(Ok(result)) = result {
      let mut changeset = GroupChangesetPB {
        view_id: self.view_id.clone(),
        ..Default::default()
      };
      if let Some(inserted_group) = result.inserted_group {
        tracing::trace!("Create group after editing the row: {:?}", inserted_group);
        changeset.inserted_groups.push(inserted_group);
      }
      if let Some(delete_group) = result.deleted_group {
        tracing::trace!("Delete group after editing the row: {:?}", delete_group);
        changeset.deleted_groups.push(delete_group.group_id);
      }
      notify_did_update_groups(&self.view_id, changeset).await;

      tracing::trace!(
        "Group changesets after editing the row: {:?}",
        result.row_changesets
      );
      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }

    let filter_controller = self.filter_controller.clone();
    let sort_controller = self.sort_controller.clone();
    let row_id = row.id;
    tokio::spawn(async move {
      filter_controller.did_receive_row_changed(row_id).await;
      sort_controller
        .read()
        .await
        .did_receive_row_changed(row_id)
        .await;
    });
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
      let mut changeset = GroupChangesetPB {
        view_id: self.view_id.clone(),
        ..Default::default()
      };
      if let Some(delete_group) = result.deleted_group {
        tracing::info!("Delete group after moving the row: {:?}", delete_group);
        changeset.deleted_groups.push(delete_group.group_id);
      }
      notify_did_update_groups(&self.view_id, changeset).await;

      for changeset in result.row_changesets {
        notify_did_update_group_rows(changeset).await;
      }
    }
  }
  /// Only call once after database view editor initialized
  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn v_load_groups(&self) -> FlowyResult<Vec<GroupPB>> {
    let groups = self
      .group_controller
      .read()
      .await
      .groups()
      .into_iter()
      .map(|group_data| GroupPB::from(group_data.clone()))
      .collect::<Vec<_>>();
    tracing::trace!("Number of groups: {}", groups.len());
    Ok(groups)
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn v_get_group(&self, group_id: &str) -> FlowyResult<GroupPB> {
    match self.group_controller.read().await.get_group(group_id) {
      None => Err(FlowyError::record_not_found().context("Can't find the group")),
      Some((_, group)) => Ok(GroupPB::from(group)),
    }
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_move_group(&self, from_group: &str, to_group: &str) -> FlowyResult<()> {
    self
      .group_controller
      .write()
      .await
      .move_group(from_group, to_group)?;
    match self.group_controller.read().await.get_group(from_group) {
      None => tracing::warn!("Can not find the group with id: {}", from_group),
      Some((index, group)) => {
        let inserted_group = InsertedGroupPB {
          group: GroupPB::from(group),
          index: index as i32,
        };

        let changeset = GroupChangesetPB {
          view_id: self.view_id.clone(),
          inserted_groups: vec![inserted_group],
          deleted_groups: vec![from_group.to_string()],
          update_groups: vec![],
          initial_groups: vec![],
        };

        notify_did_update_groups(&self.view_id, changeset).await;
      },
    }
    Ok(())
  }

  pub async fn group_id(&self) -> String {
    self.group_controller.read().await.field_id().to_string()
  }

  pub async fn v_initialize_new_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    if self.group_controller.read().await.field_id() != params.field_id {
      self.v_update_group_setting(&params.field_id).await?;

      if let Some(view) = self.delegate.get_view_setting(&self.view_id).await {
        let setting = database_view_setting_pb_from_view(view);
        notify_did_update_setting(&self.view_id, setting).await;
      }
    }
    Ok(())
  }

  pub async fn v_delete_group(&self, _params: DeleteGroupParams) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn v_get_all_sorts(&self) -> Vec<Sort> {
    self.delegate.get_all_sorts(&self.view_id)
  }

  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn v_insert_sort(&self, params: AlterSortParams) -> FlowyResult<Sort> {
    let is_exist = params.sort_id.is_some();
    let sort_id = match params.sort_id {
      None => gen_database_sort_id(),
      Some(sort_id) => sort_id,
    };

    let sort = Sort {
      id: sort_id,
      field_id: params.field_id.clone(),
      field_type: params.field_type,
      condition: params.condition.into(),
    };
    let sort_type = SortType::from(&sort);
    let mut sort_controller = self.sort_controller.write().await;
    let changeset = if is_exist {
      self.delegate.insert_sort(&self.view_id, sort.clone());
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
  pub async fn v_insert_filter(&self, params: AlterFilterParams) -> FlowyResult<()> {
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
      .delete_filter(&self.view_id, &filter_type.field_id);
    if changeset.is_some() {
      notify_did_update_filter(changeset.unwrap()).await;
    }
    Ok(())
  }

  /// Returns the current calendar settings
  #[tracing::instrument(level = "debug", skip(self))]
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

    tracing::debug!("{:?}", layout_setting);
    layout_setting
  }

  /// Update the calendar settings and send the notification to refresh the UI
  pub async fn v_set_layout_settings(
    &self,
    _layout_ty: &DatabaseLayout,
    params: LayoutSettingParams,
  ) -> FlowyResult<()> {
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

        let layout_ty = DatabaseLayout::Calendar;
        let old_calender_setting = self.v_get_layout_settings(&layout_ty).await.calendar;

        self
          .delegate
          .insert_layout_setting(&self.view_id, new_calendar_setting.clone().into());
        let new_field_id = new_calendar_setting.field_id.clone();
        let layout_setting_pb: LayoutSettingPB = LayoutSettingParams {
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
        } else {
          tracing::warn!("Calendar setting should not be empty")
        }
      }
    }

    Ok(())
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn v_did_update_field_type_option(
    &self,
    field_id: &str,
    _old_field: &Field,
  ) -> FlowyResult<()> {
    if let Some(field) = self.delegate.get_field(field_id).await {
      self
        .sort_controller
        .read()
        .await
        .did_update_view_field_type_option(&field)
        .await;

      // let filter = self
      //   .delegate
      //   .get_filter_by_field_id(&self.view_id, field_id);
      //
      // let old = old_field.map(|old_field| FilterType::from(filter));
      // let new = FilterType::from(field.as_ref());
      // let filter_type = UpdatedFilterType::new(old, new);
      // let filter_changeset = FilterChangeset::from_update(filter_type);
      // let filter_controller = self.filter_controller.clone();
      // let _ = tokio::spawn(async move {
      //   if let Some(notification) = filter_controller
      //     .did_receive_changes(filter_changeset)
      //     .await
      //   {
      //     send_notification(&notification.view_id, DatabaseNotification::DidUpdateFilter)
      //       .payload(notification)
      //       .send();
      //   }
      // });
    }
    Ok(())
  }

  ///
  ///
  /// # Arguments
  ///
  /// * `field_id`:
  ///
  #[tracing::instrument(level = "debug", skip_all, err)]
  pub async fn v_update_group_setting(&self, field_id: &str) -> FlowyResult<()> {
    if let Some(field) = self.delegate.get_field(field_id).await {
      let new_group_controller =
        new_group_controller_with_field(self.view_id.clone(), self.delegate.clone(), field).await?;

      let new_groups = new_group_controller
        .groups()
        .into_iter()
        .map(|group| GroupPB::from(group.clone()))
        .collect();

      *self.group_controller.write().await = new_group_controller;
      let changeset = GroupChangesetPB {
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
    let text_cell = get_cell_for_row(self.delegate.clone(), &primary_field.id, row_id).await?;

    // Date
    let date_field = self.delegate.get_field(&calendar_setting.field_id).await?;

    let date_cell = get_cell_for_row(self.delegate.clone(), &date_field.id, row_id).await?;
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
      row_id: row_id.into(),
      title_field_id: primary_field.id.clone(),
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
      let row_id = date_cell.row_id;

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
      let title_field_id = text_cell.field_id.clone();
      let row_id = text_cell.row_id;
      let timestamp = timestamp_by_row_id
        .get(&row_id)
        .cloned()
        .unwrap_or_default();

      let title = text_cell
        .into_text_field_cell_data()
        .unwrap_or_default()
        .into();

      let event = CalendarEventPB {
        row_id: row_id.into(),
        title_field_id,
        title,
        timestamp,
      };
      events.push(event);
    }
    Some(events)
  }

  pub async fn handle_block_event(&self, event: Cow<'_, DatabaseRowEvent>) {
    let changeset = match event.into_owned() {
      DatabaseRowEvent::InsertRow { row } => {
        RowsChangesetPB::from_insert(self.view_id.clone(), vec![row.into()])
      },
      DatabaseRowEvent::UpdateRow { row } => {
        RowsChangesetPB::from_update(self.view_id.clone(), vec![row.into()])
      },
      DatabaseRowEvent::DeleteRow { row_id } => {
        RowsChangesetPB::from_delete(self.view_id.clone(), vec![row_id])
      },
      DatabaseRowEvent::Move {
        deleted_row_id,
        inserted_row,
      } => RowsChangesetPB::from_move(
        self.view_id.clone(),
        vec![deleted_row_id],
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
    let group_field_id = self.group_controller.read().await.field_id().to_owned();
    match self.delegate.get_field(&group_field_id).await {
      None => None,
      Some(field) => {
        let mut write_guard = self.group_controller.write().await;
        f(&mut write_guard, field).ok()
      },
    }
  }
}
