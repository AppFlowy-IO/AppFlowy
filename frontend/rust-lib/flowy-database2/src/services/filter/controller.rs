use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;

use collab_database::database::gen_database_filter_id;
use collab_database::fields::Field;
use collab_database::rows::{Row, RowDetail, RowId};
use dashmap::DashMap;
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

use flowy_error::FlowyResult;
use lib_infra::future::Fut;
use lib_infra::priority_task::{QualityOfService, Task, TaskContent, TaskDispatcher};

use crate::entities::filter_entities::*;
use crate::entities::{FieldType, InsertedRowPB, RowMetaPB};
use crate::services::cell::CellCache;
use crate::services::database_view::{DatabaseViewChanged, DatabaseViewChangedNotifier};
use crate::services::field::TypeOptionCellExt;
use crate::services::filter::{Filter, FilterChangeset, FilterInner, FilterResultNotification};

pub trait FilterDelegate: Send + Sync + 'static {
  fn get_field(&self, field_id: &str) -> Option<Field>;
  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Field>>;
  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<RowDetail>>>;
  fn get_row(&self, view_id: &str, rows_id: &RowId) -> Fut<Option<(usize, Arc<RowDetail>)>>;
  fn save_filters(&self, view_id: &str, filters: &[Filter]);
}

pub struct FilterController {
  view_id: String,
  handler_id: String,
  delegate: Box<dyn FilterDelegate>,
  result_by_row_id: DashMap<RowId, bool>,
  cell_cache: CellCache,
  filters: RwLock<Vec<Filter>>,
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
    filters: Vec<Filter>,
    cell_cache: CellCache,
    notifier: DatabaseViewChangedNotifier,
  ) -> Self
  where
    T: FilterDelegate + 'static,
  {
    Self {
      view_id: view_id.to_string(),
      handler_id: handler_id.to_string(),
      delegate: Box::new(delegate),
      result_by_row_id: DashMap::default(),
      cell_cache,
      filters: RwLock::new(filters),
      task_scheduler,
      notifier,
    }
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

  pub async fn filter_rows(&self, rows: &mut Vec<Arc<RowDetail>>) {
    let filters = self.filters.read().await;

    if filters.is_empty() {
      return;
    }
    let field_by_field_id = self.get_field_map().await;
    rows.iter().for_each(|row_detail| {
      let _ = filter_row(
        &row_detail.row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &filters,
      );
    });

    rows.retain(|row_detail| {
      self
        .result_by_row_id
        .get(&row_detail.row.id)
        .map(|result| *result)
        .unwrap_or(false)
    });
  }

  async fn get_field_map(&self) -> HashMap<String, Field> {
    self
      .delegate
      .get_fields(&self.view_id, None)
      .await
      .into_iter()
      .map(|field| (field.id.clone(), field))
      .collect::<HashMap<String, Field>>()
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
      FilterEvent::RowDidChanged(row_id) => self.filter_single_row(row_id).await?,
    }
    Ok(())
  }

  async fn filter_single_row(&self, row_id: RowId) -> FlowyResult<()> {
    let filters = self.filters.read().await;

    if let Some((_, row_detail)) = self.delegate.get_row(&self.view_id, &row_id).await {
      let field_by_field_id = self.get_field_map().await;
      let mut notification = FilterResultNotification::new(self.view_id.clone());
      if let Some((row_id, is_visible)) = filter_row(
        &row_detail.row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &filters,
      ) {
        if is_visible {
          if let Some((index, _row)) = self.delegate.get_row(&self.view_id, &row_id).await {
            notification.visible_rows.push(
              InsertedRowPB::new(RowMetaPB::from(row_detail.as_ref())).with_index(index as i32),
            )
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
    let filters = self.filters.read().await;

    let field_by_field_id = self.get_field_map().await;
    let mut visible_rows = vec![];
    let mut invisible_rows = vec![];

    for (index, row_detail) in self
      .delegate
      .get_rows(&self.view_id)
      .await
      .into_iter()
      .enumerate()
    {
      if let Some((row_id, is_visible)) = filter_row(
        &row_detail.row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &filters,
      ) {
        if is_visible {
          let row_meta = RowMetaPB::from(row_detail.as_ref());
          visible_rows.push(InsertedRowPB::new(row_meta).with_index(index as i32))
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
    tracing::trace!("filter result {:?}", filters);
    let _ = self
      .notifier
      .send(DatabaseViewChanged::FilterNotification(notification));

    Ok(())
  }

  pub async fn did_receive_row_changed(&self, row_id: RowId) {
    if !self.filters.read().await.is_empty() {
      self
        .gen_task(
          FilterEvent::RowDidChanged(row_id),
          QualityOfService::UserInteractive,
        )
        .await
    }
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn apply_changeset(&self, changeset: FilterChangeset) -> FilterChangesetNotificationPB {
    let mut filters = self.filters.write().await;

    match changeset {
      FilterChangeset::Insert {
        parent_filter_id,
        data,
      } => {
        let new_filter = Filter {
          id: gen_database_filter_id(),
          inner: data,
        };
        match parent_filter_id {
          Some(parent_filter_id) => {
            if let Some(parent_filter) = filters
              .iter_mut()
              .find_map(|filter| filter.find_filter(&parent_filter_id))
            {
              // TODO(RS): error handling for inserting filters
              let _result = parent_filter.insert_filter(new_filter);
            }
          },
          None => {
            filters.push(new_filter);
          },
        }
      },
      FilterChangeset::UpdateType {
        filter_id,
        filter_type,
      } => {
        for filter in filters.iter_mut() {
          let filter = filter.find_filter(&filter_id);
          if let Some(filter) = filter {
            let result = filter.convert_to_and_or_filter_type(filter_type);
            if result.is_ok() {
              break;
            }
          }
        }
      },
      FilterChangeset::UpdateData { filter_id, data } => {
        if let Some(filter) = filters
          .iter_mut()
          .find_map(|filter| filter.find_filter(&filter_id))
        {
          // TODO(RS): error handling for updating filter data
          let _result = filter.update_filter_data(data);
        }
      },
      FilterChangeset::Delete {
        filter_id,
        field_id: _,
      } => {
        for (position, filter) in filters.iter_mut().enumerate() {
          if filter.id == filter_id {
            filters.remove(position);
            break;
          }
          let parent_filter = filter.find_parent_of_filter(&filter_id);
          if let Some(filter) = parent_filter {
            let result = filter.delete_filter(&filter_id);
            if result.is_ok() {
              break;
            }
          }
        }
      },
      FilterChangeset::DeleteAllWithFieldId { field_id } => {
        let mut filter_ids: Vec<String> = vec![];
        for filter in filters.iter_mut() {
          filter.find_all_filters_with_field_id(&field_id, &mut filter_ids);
        }

        for filter_id in filter_ids {
          for (position, filter) in filters.iter_mut().enumerate() {
            if filter.id == filter_id {
              filters.remove(position);
              break;
            }
            let parent_filter = filter.find_parent_of_filter(&filter_id);
            if let Some(filter) = parent_filter {
              let _ = filter.delete_filter(&filter_id);
            }
          }
        }
      },
    }

    self.delegate.save_filters(&self.view_id, &filters);

    self
      .gen_task(FilterEvent::FilterDidChanged, QualityOfService::Background)
      .await;

    FilterChangesetNotificationPB::from_filters(&self.view_id, &filters)
  }
}

/// Returns `Some` if the visibility of the row changed after applying the filter and `None`
/// otherwise
#[tracing::instrument(level = "trace", skip_all)]
fn filter_row(
  row: &Row,
  result_by_row_id: &DashMap<RowId, bool>,
  field_by_field_id: &HashMap<String, Field>,
  cell_data_cache: &CellCache,
  filters: &Vec<Filter>,
) -> Option<(RowId, bool)> {
  // Create a filter result cache if it doesn't exist
  let mut filter_result = result_by_row_id.entry(row.id.clone()).or_insert(true);
  let old_is_visible = *filter_result;

  let mut new_is_visible = true;
  for filter in filters {
    if let Some(is_visible) = apply_filter(row, field_by_field_id, cell_data_cache, filter) {
      new_is_visible = new_is_visible && is_visible;
    }
  }

  *filter_result = new_is_visible;

  if old_is_visible != new_is_visible {
    Some((row.id.clone(), new_is_visible))
  } else {
    None
  }
}

/// Recursively applies a `Filter` to a `Row`'s cells.
fn apply_filter(
  row: &Row,
  field_by_field_id: &HashMap<String, Field>,
  cell_data_cache: &CellCache,
  filter: &Filter,
) -> Option<bool> {
  match &filter.inner {
    FilterInner::And { children } => {
      if children.is_empty() {
        return None;
      }
      for child_filter in children.iter() {
        if let Some(false) = apply_filter(row, field_by_field_id, cell_data_cache, child_filter) {
          return Some(false);
        }
      }
      Some(true)
    },
    FilterInner::Or { children } => {
      if children.is_empty() {
        return None;
      }
      for child_filter in children.iter() {
        if let Some(true) = apply_filter(row, field_by_field_id, cell_data_cache, child_filter) {
          return Some(true);
        }
      }
      Some(false)
    },
    FilterInner::Data {
      field_id,
      field_type,
      condition_and_content,
    } => {
      let field = match field_by_field_id.get(field_id) {
        Some(field) => field,
        None => {
          tracing::error!("cannot find field");
          return Some(false);
        },
      };
      if *field_type != FieldType::from(field.field_type) {
        tracing::error!("field type of filter doesn't match field type of field");
        return Some(false);
      }
      let cell = row.cells.get(field_id).cloned();
      let field_type = FieldType::from(field.field_type);
      if let Some(handler) = TypeOptionCellExt::new(field, Some(cell_data_cache.clone()))
        .get_type_option_cell_data_handler(&field_type)
      {
        Some(handler.handle_cell_filter(field, &cell.unwrap_or_default(), condition_and_content))
      } else {
        Some(true)
      }
    },
  }
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
