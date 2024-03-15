use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;

use collab_database::database::gen_database_filter_id;
use collab_database::fields::Field;
use collab_database::rows::{Cell, Cells, Row, RowDetail, RowId};
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
  fn get_all_filters(&self, view_id: &str) -> Vec<Filter>;
  fn save_filters(&self, view_id: &str, filters: &[Filter]);
}

pub trait PreFillCellsWithFilter {
  fn get_compliant_cell(&self, field: &Field) -> (Option<Cell>, bool);
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
    cell_cache: CellCache,
    notifier: DatabaseViewChangedNotifier,
  ) -> Self
  where
    T: FilterDelegate + 'static,
  {
    // ensure every filter is valid
    let field_ids = delegate
      .get_fields(view_id, None)
      .await
      .into_iter()
      .map(|field| field.id)
      .collect::<Vec<_>>();

    let mut need_save = false;

    let mut filters = delegate.get_all_filters(view_id);
    let mut filtering_field_ids: HashMap<String, Vec<String>> = HashMap::new();

    for filter in filters.iter() {
      filter.get_all_filtering_field_ids(&mut filtering_field_ids);
    }

    let mut delete_filter_ids = vec![];

    for (field_id, filter_ids) in &filtering_field_ids {
      if !field_ids.contains(field_id) {
        need_save = true;
        delete_filter_ids.extend(filter_ids);
      }
    }

    for filter_id in delete_filter_ids {
      Self::delete_filter(&mut filters, filter_id);
    }

    if need_save {
      delegate.save_filters(view_id, &filters);
    }

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
      } => Self::delete_filter(&mut filters, &filter_id),
      FilterChangeset::DeleteAllWithFieldId { field_id } => {
        let mut filter_ids = vec![];
        for filter in filters.iter() {
          filter.find_all_filters_with_field_id(&field_id, &mut filter_ids);
        }
        for filter_id in filter_ids {
          Self::delete_filter(&mut filters, &filter_id)
        }
      },
    }

    self.delegate.save_filters(&self.view_id, &filters);

    self
      .gen_task(FilterEvent::FilterDidChanged, QualityOfService::Background)
      .await;

    FilterChangesetNotificationPB::from_filters(&self.view_id, &filters)
  }

  pub async fn fill_cells(&self, cells: &mut Cells) -> bool {
    let filters = self.filters.read().await;

    let mut open_after_create = false;

    let mut min_required_filters: Vec<&FilterInner> = vec![];
    for filter in filters.iter() {
      filter.get_min_effective_filters(&mut min_required_filters);
    }

    let field_map = self.get_field_map().await;

    while let Some(current_inner) = min_required_filters.pop() {
      if let FilterInner::Data {
        field_id,
        field_type,
        condition_and_content,
      } = &current_inner
      {
        if min_required_filters.iter().any(
          |inner| matches!(inner, FilterInner::Data { field_id: other_id, .. } if other_id == field_id),
        ) {
          min_required_filters.retain(
            |inner| matches!(inner, FilterInner::Data { field_id: other_id, .. } if other_id != field_id),
          );
          open_after_create = true;
          continue;
        }

        if let Some(field) = field_map.get(field_id) {
          let (cell, flag) = match field_type {
            FieldType::RichText | FieldType::URL => {
              let filter = condition_and_content.cloned::<TextFilterPB>().unwrap();
              filter.get_compliant_cell(field)
            },
            FieldType::Number => {
              let filter = condition_and_content.cloned::<NumberFilterPB>().unwrap();
              filter.get_compliant_cell(field)
            },
            FieldType::DateTime => {
              let filter = condition_and_content.cloned::<DateFilterPB>().unwrap();
              filter.get_compliant_cell(field)
            },
            FieldType::SingleSelect => {
              let filter = condition_and_content
                .cloned::<SelectOptionFilterPB>()
                .unwrap();
              filter.get_compliant_cell(field)
            },
            FieldType::MultiSelect => {
              let filter = condition_and_content
                .cloned::<SelectOptionFilterPB>()
                .unwrap();
              filter.get_compliant_cell(field)
            },
            FieldType::Checkbox => {
              let filter = condition_and_content.cloned::<CheckboxFilterPB>().unwrap();
              filter.get_compliant_cell(field)
            },
            FieldType::Checklist => {
              let filter = condition_and_content.cloned::<ChecklistFilterPB>().unwrap();
              filter.get_compliant_cell(field)
            },
            _ => (None, false),
          };

          if let Some(cell) = cell {
            cells.insert(field_id.clone(), cell);
          }

          if flag {
            open_after_create = flag;
          }
        }
      }
    }

    open_after_create
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
      FilterEvent::FilterDidChanged => self.filter_all_rows_handler().await?,
      FilterEvent::RowDidChanged(row_id) => self.filter_single_row_handler(row_id).await?,
    }
    Ok(())
  }

  async fn filter_single_row_handler(&self, row_id: RowId) -> FlowyResult<()> {
    let filters = self.filters.read().await;

    if let Some((_, row_detail)) = self.delegate.get_row(&self.view_id, &row_id).await {
      let field_by_field_id = self.get_field_map().await;
      let mut notification = FilterResultNotification::new(self.view_id.clone());
      if let Some(is_visible) = filter_row(
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

  async fn filter_all_rows_handler(&self) -> FlowyResult<()> {
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
      if let Some(is_visible) = filter_row(
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
          invisible_rows.push(row_detail.row.id.clone());
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

  async fn get_field_map(&self) -> HashMap<String, Field> {
    self
      .delegate
      .get_fields(&self.view_id, None)
      .await
      .into_iter()
      .map(|field| (field.id.clone(), field))
      .collect::<HashMap<String, Field>>()
  }

  fn delete_filter(filters: &mut Vec<Filter>, filter_id: &str) {
    let mut find_root_filter: Option<usize> = None;
    let mut find_parent_of_non_root_filter: Option<&mut Filter> = None;

    for (position, filter) in filters.iter_mut().enumerate() {
      if filter.id == filter_id {
        find_root_filter = Some(position);
        break;
      }
      if let Some(filter) = filter.find_parent_of_filter(filter_id) {
        find_parent_of_non_root_filter = Some(filter);
        break;
      }
    }

    if let Some(pos) = find_root_filter {
      filters.remove(pos);
    } else if let Some(filter) = find_parent_of_non_root_filter {
      if let Err(err) = filter.delete_filter(filter_id) {
        tracing::error!("error while deleting filter: {}", err);
      }
    }
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
) -> Option<bool> {
  // Create a filter result cache if it doesn't exist
  let mut filter_result = result_by_row_id.entry(row.id.clone()).or_insert(true);
  let old_is_visible = *filter_result;

  let mut new_is_visible = true;

  for filter in filters {
    if let Some(is_visible) = apply_filter(row, field_by_field_id, cell_data_cache, filter) {
      new_is_visible = new_is_visible && is_visible;

      // short-circuit as soon as one filter tree returns false
      if !new_is_visible {
        break;
      }
    }
  }

  *filter_result = new_is_visible;

  if old_is_visible != new_is_visible {
    Some(new_is_visible)
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
