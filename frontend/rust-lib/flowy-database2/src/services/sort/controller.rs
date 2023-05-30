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
use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use lib_infra::future::Fut;

use crate::entities::FieldType;
use crate::entities::SortChangesetNotificationPB;
use crate::services::cell::CellCache;
use crate::services::database_view::{DatabaseViewChanged, DatabaseViewChangedNotifier};
use crate::services::field::{default_order, TypeOptionCellExt};
use crate::services::sort::{
  ReorderAllRowsResult, ReorderSingleRowResult, Sort, SortChangeset, SortCondition,
};

pub trait SortDelegate: Send + Sync {
  fn get_sort(&self, view_id: &str, sort_id: &str) -> Fut<Option<Arc<Sort>>>;
  /// Returns all the rows after applying grid's filter
  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>>;
  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>>;
  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>>;
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
    let task_type = SortEvent::RowDidChanged(row_id);
    if !self.sorts.is_empty() {
      self.gen_task(task_type, QualityOfService::Background).await;
    }
  }

  // #[tracing::instrument(name = "process_sort_task", level = "trace", skip_all, err)]
  pub async fn process(&mut self, predicate: &str) -> FlowyResult<()> {
    let event_type = SortEvent::from_str(predicate).unwrap();
    let mut rows = self.delegate.get_rows(&self.view_id).await;
    match event_type {
      SortEvent::SortDidChanged | SortEvent::DeleteAllSorts => {
        self.sort_rows(&mut rows).await;
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

  pub async fn sort_rows(&mut self, rows: &mut Vec<Arc<Row>>) {
    if self.sorts.is_empty() {
      return;
    }

    let field_revs = self.delegate.get_fields(&self.view_id, None).await;
    for sort in self.sorts.iter() {
      rows.par_sort_by(|left, right| cmp_row(left, right, sort, &field_revs, &self.cell_cache));
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
  pub async fn did_receive_changes(
    &mut self,
    changeset: SortChangeset,
  ) -> SortChangesetNotificationPB {
    let mut notification = SortChangesetNotificationPB::new(self.view_id.clone());
    if let Some(insert_sort) = changeset.insert_sort {
      if let Some(sort) = self
        .delegate
        .get_sort(&self.view_id, &insert_sort.sort_id)
        .await
      {
        notification.insert_sorts.push(sort.as_ref().into());
        self.sorts.push(sort);
      }
    }

    if let Some(delete_sort_type) = changeset.delete_sort {
      if let Some(index) = self
        .sorts
        .iter()
        .position(|sort| sort.id == delete_sort_type.sort_id)
      {
        let sort = self.sorts.remove(index);
        notification.delete_sorts.push(sort.as_ref().into());
      }
    }

    if let Some(update_sort) = changeset.update_sort {
      if let Some(updated_sort) = self
        .delegate
        .get_sort(&self.view_id, &update_sort.sort_id)
        .await
      {
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
  left: &Arc<Row>,
  right: &Arc<Row>,
  sort: &Arc<Sort>,
  field_revs: &[Arc<Field>],
  cell_data_cache: &CellCache,
) -> Ordering {
  let order = match (
    left.cells.get(&sort.field_id),
    right.cells.get(&sort.field_id),
  ) {
    (Some(left_cell), Some(right_cell)) => {
      let field_type = sort.field_type.clone();
      match field_revs
        .iter()
        .find(|field_rev| field_rev.id == sort.field_id)
      {
        None => default_order(),
        Some(field_rev) => cmp_cell(
          left_cell,
          right_cell,
          field_rev,
          field_type,
          cell_data_cache,
        ),
      }
    },
    (Some(_), None) => Ordering::Greater,
    (None, Some(_)) => Ordering::Less,
    _ => default_order(),
  };

  // The order is calculated by Ascending. So reverse the order if the SortCondition is descending.
  match sort.condition {
    SortCondition::Ascending => order,
    SortCondition::Descending => order.reverse(),
  }
}

fn cmp_cell(
  left_cell: &Cell,
  right_cell: &Cell,
  field: &Arc<Field>,
  field_type: FieldType,
  cell_data_cache: &CellCache,
) -> Ordering {
  match TypeOptionCellExt::new_with_cell_data_cache(field.as_ref(), Some(cell_data_cache.clone()))
    .get_type_option_cell_data_handler(&field_type)
  {
    None => default_order(),
    Some(handler) => {
      let cal_order = || {
        let order = handler.handle_cell_compare(left_cell, right_cell, field.as_ref());
        Option::<Ordering>::Some(order)
      };

      cal_order().unwrap_or_else(default_order)
    },
  }
}
#[derive(Serialize, Deserialize, Clone, Debug)]
enum SortEvent {
  SortDidChanged,
  RowDidChanged(RowId),
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
