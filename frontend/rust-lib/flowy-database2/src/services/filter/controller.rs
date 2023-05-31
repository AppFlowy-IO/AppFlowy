use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{Cell, Row, RowId};
use dashmap::DashMap;
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

use flowy_error::FlowyResult;
use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use lib_infra::future::Fut;

use crate::entities::filter_entities::*;
use crate::entities::{FieldType, InsertedRowPB, RowPB};
use crate::services::cell::{AnyTypeCache, CellCache, CellFilterCache};
use crate::services::database_view::{DatabaseViewChanged, DatabaseViewChangedNotifier};
use crate::services::field::*;
use crate::services::filter::{Filter, FilterChangeset, FilterResult, FilterResultNotification};

pub trait FilterDelegate: Send + Sync + 'static {
  fn get_filter(&self, view_id: &str, filter_id: &str) -> Fut<Option<Arc<Filter>>>;
  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>>;
  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>>;
  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>>;
  fn get_row(&self, view_id: &str, rows_id: &RowId) -> Fut<Option<(usize, Arc<Row>)>>;
}

pub trait FromFilterString {
  fn from_filter(filter: &Filter) -> Self
  where
    Self: Sized;
}

pub struct FilterController {
  view_id: String,
  handler_id: String,
  delegate: Box<dyn FilterDelegate>,
  result_by_row_id: DashMap<RowId, FilterResult>,
  cell_cache: CellCache,
  cell_filter_cache: CellFilterCache,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  notifier: DatabaseViewChangedNotifier,
}

impl Drop for FilterController {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl FilterController {
  pub async fn new<T>(
    view_id: &str,
    handler_id: &str,
    delegate: T,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    filters: Vec<Arc<Filter>>,
    cell_cache: CellCache,
    notifier: DatabaseViewChangedNotifier,
  ) -> Self
  where
    T: FilterDelegate + 'static,
  {
    let this = Self {
      view_id: view_id.to_string(),
      handler_id: handler_id.to_string(),
      delegate: Box::new(delegate),
      result_by_row_id: DashMap::default(),
      cell_cache,
      // Cache by field_id
      cell_filter_cache: AnyTypeCache::<String>::new(),
      task_scheduler,
      notifier,
    };
    this.refresh_filters(filters).await;
    this
  }

  pub async fn close(&self) {
    if let Ok(mut task_scheduler) = self.task_scheduler.try_write() {
      task_scheduler.unregister_handler(&self.handler_id).await;
    } else {
      tracing::error!("Try to get the lock of task_scheduler failed");
    }
  }

  #[tracing::instrument(name = "schedule_filter_task", level = "trace", skip(self))]
  async fn gen_task(&self, task_type: FilterEvent, qos: QualityOfService) {
    let task_id = self.task_scheduler.read().await.next_task_id();
    let task = Task::new(
      &self.handler_id,
      task_id,
      TaskContent::Text(task_type.to_string()),
      qos,
    );
    self.task_scheduler.write().await.add_task(task);
  }

  pub async fn filter_rows(&self, rows: &mut Vec<Arc<Row>>) {
    if self.cell_filter_cache.read().is_empty() {
      return;
    }
    let field_by_field_id = self.get_field_map().await;
    rows.iter().for_each(|row| {
      let _ = filter_row(
        row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &self.cell_filter_cache,
      );
    });

    rows.retain(|row| {
      self
        .result_by_row_id
        .get(&row.id)
        .map(|result| result.is_visible())
        .unwrap_or(false)
    });
  }

  async fn get_field_map(&self) -> HashMap<String, Arc<Field>> {
    self
      .delegate
      .get_fields(&self.view_id, None)
      .await
      .into_iter()
      .map(|field| (field.id.clone(), field))
      .collect::<HashMap<String, Arc<Field>>>()
  }

  #[tracing::instrument(
    name = "process_filter_task",
    level = "trace",
    skip_all,
    fields(filter_result),
    err
  )]
  pub async fn process(&self, predicate: &str) -> FlowyResult<()> {
    let event_type = FilterEvent::from_str(predicate).unwrap();
    match event_type {
      FilterEvent::FilterDidChanged => self.filter_all_rows().await?,
      FilterEvent::RowDidChanged(row_id) => self.filter_row(row_id).await?,
    }
    Ok(())
  }

  async fn filter_row(&self, row_id: RowId) -> FlowyResult<()> {
    if let Some((_, row)) = self.delegate.get_row(&self.view_id, &row_id).await {
      let field_by_field_id = self.get_field_map().await;
      let mut notification = FilterResultNotification::new(self.view_id.clone());
      if let Some((row_id, is_visible)) = filter_row(
        &row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &self.cell_filter_cache,
      ) {
        if is_visible {
          if let Some((index, row)) = self.delegate.get_row(&self.view_id, &row_id).await {
            let row_pb = RowPB::from(row.as_ref());
            notification
              .visible_rows
              .push(InsertedRowPB::new(row_pb).with_index(index as i32))
          }
        } else {
          notification.invisible_rows.push(row_id);
        }
      }

      let _ = self
        .notifier
        .send(DatabaseViewChanged::FilterNotification(notification));
    }
    Ok(())
  }

  async fn filter_all_rows(&self) -> FlowyResult<()> {
    let field_by_field_id = self.get_field_map().await;
    let mut visible_rows = vec![];
    let mut invisible_rows = vec![];

    for (index, row) in self
      .delegate
      .get_rows(&self.view_id)
      .await
      .into_iter()
      .enumerate()
    {
      if let Some((row_id, is_visible)) = filter_row(
        &row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &self.cell_filter_cache,
      ) {
        if is_visible {
          let row_pb = RowPB::from(row.as_ref());
          visible_rows.push(InsertedRowPB::new(row_pb).with_index(index as i32))
        } else {
          invisible_rows.push(row_id);
        }
      }
    }

    let notification = FilterResultNotification {
      view_id: self.view_id.clone(),
      invisible_rows,
      visible_rows,
    };
    tracing::Span::current().record("filter_result", format!("{:?}", &notification).as_str());
    let _ = self
      .notifier
      .send(DatabaseViewChanged::FilterNotification(notification));
    Ok(())
  }

  pub async fn did_receive_row_changed(&self, row_id: RowId) {
    if !self.cell_filter_cache.read().is_empty() {
      self
        .gen_task(
          FilterEvent::RowDidChanged(row_id),
          QualityOfService::UserInteractive,
        )
        .await
    }
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn did_receive_changes(
    &self,
    changeset: FilterChangeset,
  ) -> Option<FilterChangesetNotificationPB> {
    let mut notification: Option<FilterChangesetNotificationPB> = None;

    if let Some(filter_type) = &changeset.insert_filter {
      if let Some(filter) = self.filter_from_filter_id(&filter_type.filter_id).await {
        notification = Some(FilterChangesetNotificationPB::from_insert(
          &self.view_id,
          vec![filter],
        ));
      }
      if let Some(filter) = self
        .delegate
        .get_filter(&self.view_id, &filter_type.filter_id)
        .await
      {
        self.refresh_filters(vec![filter]).await;
      }
    }

    if let Some(updated_filter_type) = changeset.update_filter {
      if let Some(old_filter_type) = updated_filter_type.old {
        let new_filter = self
          .filter_from_filter_id(&updated_filter_type.new.filter_id)
          .await;
        let old_filter = self.filter_from_filter_id(&old_filter_type.filter_id).await;

        // Get the filter id
        let mut filter_id = old_filter.map(|filter| filter.id);
        if filter_id.is_none() {
          filter_id = new_filter.as_ref().map(|filter| filter.id.clone());
        }

        if let Some(filter_id) = filter_id {
          // Update the corresponding filter in the cache
          if let Some(filter) = self.delegate.get_filter(&self.view_id, &filter_id).await {
            self.refresh_filters(vec![filter]).await;
          }

          notification = Some(FilterChangesetNotificationPB::from_update(
            &self.view_id,
            vec![UpdatedFilter {
              filter_id,
              filter: new_filter,
            }],
          ));
        }
      }
    }

    if let Some(filter_type) = &changeset.delete_filter {
      if let Some(filter) = self.filter_from_filter_id(&filter_type.filter_id).await {
        notification = Some(FilterChangesetNotificationPB::from_delete(
          &self.view_id,
          vec![filter],
        ));
      }
      self.cell_filter_cache.write().remove(&filter_type.field_id);
    }

    self
      .gen_task(FilterEvent::FilterDidChanged, QualityOfService::Background)
      .await;
    tracing::trace!("{:?}", notification);
    notification
  }

  async fn filter_from_filter_id(&self, filter_id: &str) -> Option<FilterPB> {
    self
      .delegate
      .get_filter(&self.view_id, filter_id)
      .await
      .map(|filter| FilterPB::from(filter.as_ref()))
  }

  #[tracing::instrument(level = "trace", skip_all)]
  async fn refresh_filters(&self, filters: Vec<Arc<Filter>>) {
    for filter in filters {
      let field_id = &filter.field_id;
      tracing::trace!("Create filter with type: {:?}", filter.field_type);
      match &filter.field_type {
        FieldType::RichText => {
          self
            .cell_filter_cache
            .write()
            .insert(field_id, TextFilterPB::from_filter(filter.as_ref()));
        },
        FieldType::Number => {
          self
            .cell_filter_cache
            .write()
            .insert(field_id, NumberFilterPB::from_filter(filter.as_ref()));
        },
        FieldType::DateTime | FieldType::LastEditedTime | FieldType::CreatedTime => {
          self
            .cell_filter_cache
            .write()
            .insert(field_id, DateFilterPB::from_filter(filter.as_ref()));
        },
        FieldType::SingleSelect | FieldType::MultiSelect => {
          self
            .cell_filter_cache
            .write()
            .insert(field_id, SelectOptionFilterPB::from_filter(filter.as_ref()));
        },
        FieldType::Checkbox => {
          self
            .cell_filter_cache
            .write()
            .insert(field_id, CheckboxFilterPB::from_filter(filter.as_ref()));
        },
        FieldType::URL => {
          self
            .cell_filter_cache
            .write()
            .insert(field_id, TextFilterPB::from_filter(filter.as_ref()));
        },
        FieldType::Checklist => {
          self
            .cell_filter_cache
            .write()
            .insert(field_id, ChecklistFilterPB::from_filter(filter.as_ref()));
        },
      }
    }
  }
}

/// Returns None if there is no change in this row after applying the filter
#[tracing::instrument(level = "trace", skip_all)]
fn filter_row(
  row: &Row,
  result_by_row_id: &DashMap<RowId, FilterResult>,
  field_by_field_id: &HashMap<String, Arc<Field>>,
  cell_data_cache: &CellCache,
  cell_filter_cache: &CellFilterCache,
) -> Option<(RowId, bool)> {
  // Create a filter result cache if it's not exist
  let mut filter_result = result_by_row_id
    .entry(row.id.clone())
    .or_insert_with(FilterResult::default);
  let old_is_visible = filter_result.is_visible();

  // Iterate each cell of the row to check its visibility
  for (field_id, field) in field_by_field_id {
    if !cell_filter_cache.read().contains(field_id) {
      filter_result.visible_by_field_id.remove(field_id);
      continue;
    }

    let cell = row.cells.get(field_id).cloned();
    let field_type = FieldType::from(field.field_type);
    // if the visibility of the cell_rew is changed, which means the visibility of the
    // row is changed too.
    if let Some(is_visible) =
      filter_cell(&field_type, field, cell, cell_data_cache, cell_filter_cache)
    {
      filter_result
        .visible_by_field_id
        .insert(field_id.to_string(), is_visible);
    }
  }

  let is_visible = filter_result.is_visible();
  if old_is_visible != is_visible {
    Some((row.id.clone(), is_visible))
  } else {
    None
  }
}

// Returns None if there is no change in this cell after applying the filter
// Returns Some if the visibility of the cell is changed

#[tracing::instrument(level = "trace", skip_all, fields(cell_content))]
fn filter_cell(
  field_type: &FieldType,
  field: &Arc<Field>,
  cell: Option<Cell>,
  cell_data_cache: &CellCache,
  cell_filter_cache: &CellFilterCache,
) -> Option<bool> {
  let handler = TypeOptionCellExt::new(
    field.as_ref(),
    Some(cell_data_cache.clone()),
    Some(cell_filter_cache.clone()),
  )
  .get_type_option_cell_data_handler(field_type)?;
  let is_visible =
    handler.handle_cell_filter(field_type, field.as_ref(), &cell.unwrap_or_default());
  Some(is_visible)
}

#[derive(Serialize, Deserialize, Clone, Debug)]
enum FilterEvent {
  FilterDidChanged,
  RowDidChanged(RowId),
}

impl ToString for FilterEvent {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}

impl FromStr for FilterEvent {
  type Err = serde_json::Error;
  fn from_str(s: &str) -> Result<Self, Self::Err> {
    serde_json::from_str(s)
  }
}
