use async_trait::async_trait;
use std::cmp::Ordering;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{Cell, Row, RowId};
use rayon::prelude::ParallelSliceMut;
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

use flowy_error::FlowyResult;
use lib_infra::priority_task::{QualityOfService, Task, TaskContent, TaskDispatcher};

use crate::entities::SortChangesetNotificationPB;
use crate::entities::{FieldType, SortWithIndexPB};
use crate::services::cell::CellCache;
use crate::services::database_view::{DatabaseViewChanged, DatabaseViewChangedNotifier};
use crate::services::field::{
  default_order, TimestampCellData, TimestampCellDataWrapper, TypeOptionCellExt,
};
use crate::services::sort::{
  InsertRowResult, ReorderAllRowsResult, ReorderSingleRowResult, Sort, SortChangeset, SortCondition,
};

#[async_trait]
pub trait SortDelegate: Send + Sync {
  async fn get_sort(&self, view_id: &str, sort_id: &str) -> Option<Arc<Sort>>;
  /// Returns all the rows after applying grid's filter
  async fn get_rows(&self, view_id: &str) -> Vec<Arc<Row>>;
  async fn filter_row(&self, row_detail: &Row) -> bool;
  async fn get_field(&self, field_id: &str) -> Option<Field>;
  async fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Vec<Field>;
}

pub struct SortController {
  view_id: String,
  handler_id: String,
  delegate: Box<dyn SortDelegate>,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  sorts: Vec<Arc<Sort>>,
  cell_cache: CellCache,
  row_index_cache: HashMap<RowId, usize>,
  notifier: DatabaseViewChangedNotifier,
}

impl Drop for SortController {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl SortController {
  pub fn new<T>(
    view_id: &str,
    handler_id: &str,
    sorts: Vec<Arc<Sort>>,
    delegate: T,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    cell_cache: CellCache,
    notifier: DatabaseViewChangedNotifier,
  ) -> Self
  where
    T: SortDelegate + 'static,
  {
    Self {
      view_id: view_id.to_string(),
      handler_id: handler_id.to_string(),
      delegate: Box::new(delegate),
      task_scheduler,
      sorts,
      cell_cache,
      row_index_cache: Default::default(),
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

  pub async fn did_receive_row_changed(&self, row_id: RowId) {
    if !self.sorts.is_empty() {
      self
        .gen_task(
          SortEvent::RowDidChanged(row_id),
          QualityOfService::Background,
        )
        .await;
    }
  }

  pub async fn did_create_row(&self, preliminary_index: usize, row: &Row) {
    if !self.delegate.filter_row(row).await {
      return;
    }

    if !self.sorts.is_empty() {
      self
        .gen_task(
          SortEvent::NewRowInserted(row.clone()),
          QualityOfService::Background,
        )
        .await;
    } else {
      let result = InsertRowResult {
        view_id: self.view_id.clone(),
        row: row.clone(),
        index: preliminary_index,
      };
      let _ = self
        .notifier
        .send(DatabaseViewChanged::InsertRowNotification(result));
    }
  }

  pub async fn did_update_field_type(&self) {
    if !self.sorts.is_empty() {
      self
        .gen_task(SortEvent::SortDidChanged, QualityOfService::Background)
        .await;
    }
  }

  // #[tracing::instrument(name = "process_sort_task", level = "trace", skip_all, err)]
  pub async fn process(&mut self, predicate: &str) -> FlowyResult<()> {
    let event_type = SortEvent::from_str(predicate).unwrap();
    let mut rows = self.delegate.get_rows(&self.view_id).await;

    match event_type {
      SortEvent::SortDidChanged | SortEvent::DeleteAllSorts => {
        self.sort_rows_and_notify(&mut rows).await;
      },
      SortEvent::RowDidChanged(row_id) => {
        let old_row_index = self.row_index_cache.get(&row_id).cloned();
        self.sort_rows(&mut rows).await;
        let new_row_index = self.row_index_cache.get(&row_id).cloned();
        match (old_row_index, new_row_index) {
          (Some(old_row_index), Some(new_row_index)) => {
            if old_row_index == new_row_index {
              return Ok(());
            }
            let notification = ReorderSingleRowResult {
              row_id,
              view_id: self.view_id.clone(),
              old_index: old_row_index,
              new_index: new_row_index,
            };
            let _ = self
              .notifier
              .send(DatabaseViewChanged::ReorderSingleRowNotification(
                notification,
              ));
          },
          _ => tracing::trace!("The row index cache is outdated"),
        }
      },
      SortEvent::NewRowInserted(row) => {
        self.sort_rows(&mut rows).await;
        let row_index = self.row_index_cache.get(&row.id).cloned();
        match row_index {
          Some(row_index) => {
            let notification = InsertRowResult {
              view_id: self.view_id.clone(),
              row: row.clone(),
              index: row_index,
            };
            self.row_index_cache.insert(row.id, row_index);
            let _ = self
              .notifier
              .send(DatabaseViewChanged::InsertRowNotification(notification));
          },
          _ => tracing::trace!("The row index cache is outdated"),
        }
      },
    }
    Ok(())
  }

  #[tracing::instrument(name = "schedule_sort_task", level = "trace", skip(self))]
  async fn gen_task(&self, task_type: SortEvent, qos: QualityOfService) {
    let task_id = self.task_scheduler.read().await.next_task_id();
    let task = Task::new(
      &self.handler_id,
      task_id,
      TaskContent::Text(task_type.to_string()),
      qos,
    );
    self.task_scheduler.write().await.add_task(task);
  }

  pub async fn sort_rows_and_notify(&mut self, rows: &mut Vec<Arc<Row>>) {
    if self.sorts.is_empty() {
      return;
    }

    self.sort_rows(rows).await;
    let row_orders = rows
      .iter()
      .map(|row| row.id.to_string())
      .collect::<Vec<String>>();

    let notification = ReorderAllRowsResult {
      view_id: self.view_id.clone(),
      row_orders,
    };

    let _ = self
      .notifier
      .send(DatabaseViewChanged::ReorderAllRowsNotification(
        notification,
      ));
  }

  pub async fn sort_rows(&mut self, rows: &mut Vec<Arc<Row>>) {
    if self.sorts.is_empty() {
      return;
    }

    let fields = self.delegate.get_fields(&self.view_id, None).await;
    for sort in self.sorts.iter().rev() {
      rows.par_sort_by(|left, right| cmp_row(&left, &right, sort, &fields, &self.cell_cache));
    }
    rows.iter().enumerate().for_each(|(index, row)| {
      self.row_index_cache.insert(row.id.clone(), index);
    });
  }

  pub async fn delete_all_sorts(&mut self) {
    self.sorts.clear();
    self
      .gen_task(SortEvent::DeleteAllSorts, QualityOfService::Background)
      .await;
  }

  pub async fn did_update_field_type_option(&self, _field: &Field) {
    //
  }

  #[tracing::instrument(level = "trace", skip(self))]
  pub async fn apply_changeset(&mut self, changeset: SortChangeset) -> SortChangesetNotificationPB {
    let mut notification = SortChangesetNotificationPB::new(self.view_id.clone());

    if let Some(insert_sort) = changeset.insert_sort {
      if let Some(sort) = self.delegate.get_sort(&self.view_id, &insert_sort.id).await {
        notification.insert_sorts.push(SortWithIndexPB {
          index: self.sorts.len() as u32,
          sort: sort.as_ref().into(),
        });
        self.sorts.push(sort);
      }
    }

    if let Some(sort_id) = changeset.delete_sort {
      if let Some(index) = self.sorts.iter().position(|sort| sort.id == sort_id) {
        let sort = self.sorts.remove(index);
        notification.delete_sorts.push(sort.as_ref().into());
      }
    }

    if let Some(update_sort) = changeset.update_sort {
      if let Some(updated_sort) = self.delegate.get_sort(&self.view_id, &update_sort.id).await {
        notification.update_sorts.push(updated_sort.as_ref().into());
        if let Some(index) = self
          .sorts
          .iter()
          .position(|sort| sort.id == updated_sort.id)
        {
          self.sorts[index] = updated_sort;
        }
      }
    }

    if let Some((from_id, to_id)) = changeset.reorder_sort {
      let moved_sort = self.delegate.get_sort(&self.view_id, &from_id).await;
      let from_index = self.sorts.iter().position(|sort| sort.id == from_id);
      let to_index = self.sorts.iter().position(|sort| sort.id == to_id);

      if let (Some(sort), Some(from_index), Some(to_index)) = (moved_sort, from_index, to_index) {
        self.sorts.remove(from_index);
        self.sorts.insert(to_index, sort.clone());

        notification.delete_sorts.push(sort.as_ref().into());
        notification.insert_sorts.push(SortWithIndexPB {
          index: to_index as u32,
          sort: sort.as_ref().into(),
        });
      }
    }

    if !notification.is_empty() {
      self
        .gen_task(SortEvent::SortDidChanged, QualityOfService::UserInteractive)
        .await;
    }
    tracing::trace!("sort notification: {:?}", notification);
    notification
  }
}

fn cmp_row(
  left: &Row,
  right: &Row,
  sort: &Arc<Sort>,
  fields: &[Field],
  cell_data_cache: &CellCache,
) -> Ordering {
  match fields
    .iter()
    .find(|field_rev| field_rev.id == sort.field_id)
  {
    None => default_order(),
    Some(field_rev) => {
      let field_type = field_rev.field_type.into();
      let timestamp_cells = match field_type {
        FieldType::LastEditedTime | FieldType::CreatedTime => {
          let (left_cell, right_cell) = if field_type.is_created_time() {
            (left.created_at, right.created_at)
          } else {
            (left.modified_at, right.modified_at)
          };
          let (left_cell, right_cell) = (
            TimestampCellDataWrapper::from((field_type, TimestampCellData::new(left_cell))),
            TimestampCellDataWrapper::from((field_type, TimestampCellData::new(right_cell))),
          );
          Some((Some(left_cell.into()), Some(right_cell.into())))
        },
        _ => None,
      };

      cmp_cell(
        timestamp_cells
          .as_ref()
          .map_or_else(|| left.cells.get(&sort.field_id), |cell| cell.0.as_ref()),
        timestamp_cells
          .as_ref()
          .map_or_else(|| right.cells.get(&sort.field_id), |cell| cell.1.as_ref()),
        field_rev,
        cell_data_cache,
        sort.condition,
      )
    },
  }
}

fn cmp_cell(
  left_cell: Option<&Cell>,
  right_cell: Option<&Cell>,
  field: &Field,
  cell_data_cache: &CellCache,
  sort_condition: SortCondition,
) -> Ordering {
  match TypeOptionCellExt::new(field, Some(cell_data_cache.clone()))
    .get_type_option_cell_data_handler()
  {
    None => default_order(),
    Some(handler) => handler.handle_cell_compare(left_cell, right_cell, field, sort_condition),
  }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
enum SortEvent {
  SortDidChanged,
  RowDidChanged(RowId),
  NewRowInserted(Row),
  DeleteAllSorts,
}

impl ToString for SortEvent {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}

impl FromStr for SortEvent {
  type Err = serde_json::Error;
  fn from_str(s: &str) -> Result<Self, Self::Err> {
    serde_json::from_str(s)
  }
}
