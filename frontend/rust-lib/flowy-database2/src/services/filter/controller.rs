use async_trait::async_trait;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;

use collab::lock::RwLock;
use collab_database::database::gen_database_filter_id;
use collab_database::fields::Field;
use collab_database::rows::{Cell, Cells, Row, RowDetail, RowId};
use dashmap::DashMap;
use flowy_error::FlowyResult;
use lib_infra::priority_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use rayon::prelude::*;

use serde::{Deserialize, Serialize};
use tokio::sync::RwLock as TokioRwLock;
use tracing::{error, trace};

use crate::entities::filter_entities::*;
use crate::entities::{FieldType, InsertedRowPB, RowMetaPB};
use crate::services::cell::CellCache;
use crate::services::database_view::{DatabaseViewChanged, DatabaseViewChangedNotifier};
use crate::services::field::{TimestampCellData, TimestampCellDataWrapper, TypeOptionCellExt};
use crate::services::filter::{Filter, FilterChangeset, FilterInner, FilterResultNotification};

#[async_trait]
pub trait FilterDelegate: Send + Sync + 'static {
  async fn get_field(&self, field_id: &str) -> Option<Field>;
  async fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Vec<Field>;
  async fn get_rows(&self, view_id: &str) -> Vec<Arc<Row>>;
  async fn get_row(&self, view_id: &str, rows_id: &RowId) -> Option<(usize, Arc<RowDetail>)>;
  async fn get_all_filters(&self, view_id: &str) -> Vec<Filter>;
  async fn save_filters(&self, view_id: &str, filters: &[Filter]);
}

pub trait PreFillCellsWithFilter {
  fn get_compliant_cell(&self, field: &Field) -> Option<Cell>;
}

pub struct FilterController {
  view_id: String,
  handler_id: String,
  delegate: Box<dyn FilterDelegate>,
  result_by_row_id: DashMap<RowId, bool>,
  cell_cache: CellCache,
  filters: RwLock<Vec<Filter>>,
  task_scheduler: Arc<TokioRwLock<TaskDispatcher>>,
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
    task_scheduler: Arc<TokioRwLock<TaskDispatcher>>,
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

    let mut filters = delegate.get_all_filters(view_id).await;
    trace!("[Database]: filters: {:?}", filters);
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
      delegate.save_filters(view_id, &filters).await;
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

  pub async fn has_filters(&self) -> bool {
    !self.filters.read().await.is_empty()
  }

  pub async fn close(&self) {
    self
      .task_scheduler
      .write()
      .await
      .unregister_handler(&self.handler_id)
      .await;
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
              if let Err(err) = parent_filter.insert_filter(new_filter) {
                error!("error while inserting filter: {}", err);
              }
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
          if let Err(error) = filter.update_filter_data(data) {
            error!("error while updating filter data: {}", error);
          }
        }
      },
      FilterChangeset::Delete { filter_id } => Self::delete_filter(&mut filters, &filter_id),
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

    self.delegate.save_filters(&self.view_id, &filters).await;

    self
      .gen_task(FilterEvent::FilterDidChanged, QualityOfService::Background)
      .await;

    FilterChangesetNotificationPB::from_filters(&self.view_id, &filters)
  }

  pub async fn fill_cells(&self, cells: &mut Cells) {
    let filters = self.filters.read().await;

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
          continue;
        }

        if let Some(field) = field_map.get(field_id) {
          let cell = match field_type {
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
            FieldType::Time => {
              let filter = condition_and_content.cloned::<TimeFilterPB>().unwrap();
              filter.get_compliant_cell(field)
            },
            _ => None,
          };

          if let Some(cell) = cell {
            cells.insert(field_id.clone(), cell);
          }
        }
      }
    }
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
      FilterEvent::FilterDidChanged => {
        let mut rows = self.delegate.get_rows(&self.view_id).await;
        self.filter_rows_and_notify(&mut rows).await?
      },
      FilterEvent::RowDidChanged(row_id) => self.filter_single_row_handler(row_id).await?,
    }
    Ok(())
  }

  async fn filter_single_row_handler(&self, row_id: RowId) -> FlowyResult<()> {
    let filters = self.filters.read().await;

    if let Some((_, row_detail)) = self.delegate.get_row(&self.view_id, &row_id).await {
      let field_by_field_id = self.get_field_map().await;
      let mut notification = FilterResultNotification::new(self.view_id.clone());
      if filter_row(
        &row_detail.row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &filters,
      ) {
        if let Some((index, _row)) = self.delegate.get_row(&self.view_id, &row_id).await {
          notification.visible_rows.push(
            InsertedRowPB::new(RowMetaPB::from(row_detail.as_ref().clone()))
              .with_index(index as i32),
          )
        }
      } else {
        notification.invisible_rows.push(row_id);
      }

      let _ = self
        .notifier
        .send(DatabaseViewChanged::FilterNotification(notification));
    }
    Ok(())
  }

  pub async fn filter_rows_and_notify(&self, rows: &mut Vec<Arc<Row>>) -> FlowyResult<()> {
    let filters = self.filters.read().await;
    let field_by_field_id = self.get_field_map().await;
    let (visible_rows, invisible_rows): (Vec<_>, Vec<_>) =
      rows.par_iter().enumerate().partition_map(|(index, row)| {
        if filter_row(
          row,
          &self.result_by_row_id,
          &field_by_field_id,
          &self.cell_cache,
          &filters,
        ) {
          let row_meta = RowMetaPB::from(row.as_ref());
          // Visible rows go into the left partition
          rayon::iter::Either::Left(InsertedRowPB::new(row_meta).with_index(index as i32))
        } else {
          // Invisible rows (just IDs) go into the right partition
          rayon::iter::Either::Right(row.id.clone())
        }
      });

    let len = rows.len();
    rows.retain(|row| !invisible_rows.iter().any(|id| id == &row.id));
    trace!("[Database]: filter out {} invisible rows", len - rows.len());
    let notification = FilterResultNotification {
      view_id: self.view_id.clone(),
      invisible_rows,
      visible_rows,
    };
    let _ = self
      .notifier
      .send(DatabaseViewChanged::FilterNotification(notification));

    Ok(())
  }

  pub async fn filter_rows(&self, mut rows: Vec<Arc<Row>>) -> Vec<Arc<Row>> {
    let filters = self.filters.read().await;
    let field_by_field_id = self.get_field_map().await;
    rows.par_iter().for_each(|row| {
      let _ = filter_row(
        row,
        &self.result_by_row_id,
        &field_by_field_id,
        &self.cell_cache,
        &filters,
      );
    });

    let len = rows.len();
    rows.retain(|row| {
      self
        .result_by_row_id
        .get(&row.id)
        .map(|result| *result)
        .unwrap_or(true)
    });
    trace!("[Database]: filter out {} invisible rows", len - rows.len());
    rows
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
) -> bool {
  // Create a filter result cache if it doesn't exist
  let mut filter_result = result_by_row_id.entry(row.id.clone()).or_insert(true);
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
  new_is_visible
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
        error!("field type of filter doesn't match field type of field");
        return Some(false);
      }
      let timestamp_cell = match field_type {
        FieldType::LastEditedTime | FieldType::CreatedTime => {
          let timestamp = if field_type.is_created_time() {
            row.created_at
          } else {
            row.modified_at
          };
          let cell =
            TimestampCellDataWrapper::from((*field_type, TimestampCellData::new(timestamp)));
          Some(cell.into())
        },
        _ => None,
      };
      let cell = timestamp_cell.or_else(|| row.cells.get(field_id).cloned());
      if let Some(handler) = TypeOptionCellExt::new(field, Some(cell_data_cache.clone()))
        .get_type_option_cell_data_handler()
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
