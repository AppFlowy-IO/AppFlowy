use crate::entities::FieldType;
use crate::entities::SortChangesetNotificationPB;
use crate::services::cell::{AtomicCellDataCache, TypeCellData};
use crate::services::field::{default_order, TypeOptionCellExt};
use crate::services::sort::{ReorderAllRowsResult, ReorderSingleRowResult, SortChangeset, SortType};
use crate::services::view_editor::{GridViewChanged, GridViewChangedNotifier};
use flowy_error::FlowyResult;
use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use grid_rev_model::{CellRevision, FieldRevision, RowRevision, SortCondition, SortRevision};
use lib_infra::future::Fut;
use rayon::prelude::ParallelSliceMut;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait SortDelegate: Send + Sync {
    fn get_sort_rev(&self, sort_type: SortType) -> Fut<Option<Arc<SortRevision>>>;
    /// Returns all the rows after applying grid's filter
    fn get_row_revs(&self) -> Fut<Vec<Arc<RowRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
}

pub struct SortController {
    view_id: String,
    handler_id: String,
    delegate: Box<dyn SortDelegate>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    sorts: Vec<Arc<SortRevision>>,
    cell_data_cache: AtomicCellDataCache,
    row_index_cache: HashMap<String, usize>,
    notifier: GridViewChangedNotifier,
}

impl SortController {
    pub fn new<T>(
        view_id: &str,
        handler_id: &str,
        delegate: T,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
        cell_data_cache: AtomicCellDataCache,
        notifier: GridViewChangedNotifier,
    ) -> Self
    where
        T: SortDelegate + 'static,
    {
        Self {
            view_id: view_id.to_string(),
            handler_id: handler_id.to_string(),
            delegate: Box::new(delegate),
            task_scheduler,
            sorts: vec![],
            cell_data_cache,
            row_index_cache: Default::default(),
            notifier,
        }
    }

    pub async fn close(&self) {
        self.task_scheduler
            .write()
            .await
            .unregister_handler(&self.handler_id)
            .await;
    }

    pub async fn did_receive_row_changed(&self, row_id: &str) {
        let task_type = SortEvent::RowDidChanged(row_id.to_string());
        self.gen_task(task_type, QualityOfService::Background).await;
    }

    #[tracing::instrument(name = "receive_sort_task_result", level = "trace", skip_all, err)]
    pub async fn process(&mut self, predicate: &str) -> FlowyResult<()> {
        let event_type = SortEvent::from_str(predicate).unwrap();
        let mut row_revs = self.delegate.get_row_revs().await;
        match event_type {
            SortEvent::SortDidChanged => {
                self.sort_rows(&mut row_revs).await;
                let row_orders = row_revs
                    .iter()
                    .map(|row_rev| row_rev.id.clone())
                    .collect::<Vec<String>>();

                let notification = ReorderAllRowsResult {
                    view_id: self.view_id.clone(),
                    row_orders,
                };

                let _ = self
                    .notifier
                    .send(GridViewChanged::ReorderAllRowsNotification(notification));
            }
            SortEvent::RowDidChanged(row_id) => {
                let old_row_index = self.row_index_cache.get(&row_id).cloned();
                self.sort_rows(&mut row_revs).await;
                let new_row_index = self.row_index_cache.get(&row_id).cloned();
                match (old_row_index, new_row_index) {
                    (Some(old_row_index), Some(new_row_index)) => {
                        if old_row_index == new_row_index {
                            return Ok(());
                        }
                        let notification = ReorderSingleRowResult {
                            view_id: self.view_id.clone(),
                            old_index: old_row_index,
                            new_index: new_row_index,
                        };
                        let _ = self
                            .notifier
                            .send(GridViewChanged::ReorderSingleRowNotification(notification));
                    }
                    _ => tracing::trace!("The row index cache is outdated"),
                }
            }
        }
        Ok(())
    }

    #[tracing::instrument(name = "schedule_sort_task", level = "trace", skip(self))]
    async fn gen_task(&self, task_type: SortEvent, qos: QualityOfService) {
        if self.sorts.is_empty() {
            return;
        }
        let task_id = self.task_scheduler.read().await.next_task_id();
        let task = Task::new(&self.handler_id, task_id, TaskContent::Text(task_type.to_string()), qos);
        self.task_scheduler.write().await.add_task(task);
    }

    pub async fn sort_rows(&mut self, rows: &mut Vec<Arc<RowRevision>>) {
        if self.sorts.is_empty() {
            return;
        }

        let field_revs = self.delegate.get_field_revs(None).await;
        for sort in self.sorts.iter() {
            rows.par_sort_by(|left, right| cmp_row(left, right, sort, &field_revs, &self.cell_data_cache));
        }
        rows.iter().enumerate().for_each(|(index, row)| {
            self.row_index_cache.insert(row.id.to_string(), index);
        });
    }

    pub async fn did_update_view_field_type_option(&self, _field_rev: &FieldRevision) {
        //
    }

    #[tracing::instrument(level = "trace", skip(self))]
    pub async fn did_receive_changes(&mut self, changeset: SortChangeset) -> SortChangesetNotificationPB {
        let mut notification = SortChangesetNotificationPB::default();
        if let Some(insert_sort) = changeset.insert_sort {
            if let Some(sort) = self.delegate.get_sort_rev(insert_sort).await {
                notification.insert_sorts.push(sort.as_ref().into());
                self.sorts.push(sort);
            }
        }

        if let Some(delete_sort_type) = changeset.delete_sort {
            if let Some(index) = self.sorts.iter().position(|sort| sort.id == delete_sort_type.sort_id) {
                let sort = self.sorts.remove(index);
                notification.delete_sorts.push(sort.as_ref().into());
            }
        }

        if let Some(update_sort) = changeset.update_sort {
            if let Some(updated_sort) = self.delegate.get_sort_rev(update_sort).await {
                notification.update_sorts.push(updated_sort.as_ref().into());
                if let Some(index) = self.sorts.iter().position(|sort| sort.id == updated_sort.id) {
                    self.sorts[index] = updated_sort;
                }
            }
        }

        if !notification.insert_sorts.is_empty() || !notification.delete_sorts.is_empty() {
            self.gen_task(SortEvent::SortDidChanged, QualityOfService::Background)
                .await;
        }
        notification
    }
}

fn cmp_row(
    left: &Arc<RowRevision>,
    right: &Arc<RowRevision>,
    sort: &Arc<SortRevision>,
    field_revs: &[Arc<FieldRevision>],
    cell_data_cache: &AtomicCellDataCache,
) -> Ordering {
    let order = match (left.cells.get(&sort.field_id), right.cells.get(&sort.field_id)) {
        (Some(left_cell), Some(right_cell)) => {
            let field_type: FieldType = sort.field_type.into();
            match field_revs.iter().find(|field_rev| field_rev.id == sort.field_id) {
                None => default_order(),
                Some(field_rev) => cmp_cell(left_cell, right_cell, field_rev, field_type, cell_data_cache),
            }
        }
        (Some(_), None) => Ordering::Greater,
        (None, Some(_)) => Ordering::Less,
        _ => default_order(),
    };

    match sort.condition {
        SortCondition::Ascending => order,
        SortCondition::Descending => order.reverse(),
    }
}

fn cmp_cell(
    left_cell: &CellRevision,
    right_cell: &CellRevision,
    field_rev: &Arc<FieldRevision>,
    field_type: FieldType,
    cell_data_cache: &AtomicCellDataCache,
) -> Ordering {
    match TypeOptionCellExt::new_with_cell_data_cache(field_rev.as_ref(), Some(cell_data_cache.clone()))
        .get_type_option_cell_data_handler(&field_type)
    {
        None => Ordering::Less,
        Some(handler) => {
            let cal_order = || {
                let left_cell_str = TypeCellData::try_from(left_cell).ok()?.into_inner();
                let right_cell_str = TypeCellData::try_from(right_cell).ok()?.into_inner();
                let order = handler.handle_cell_compare(&left_cell_str, &right_cell_str, field_rev.as_ref());
                Option::<Ordering>::Some(order)
            };

            cal_order().unwrap_or_else(default_order)
        }
    }
}
#[derive(Serialize, Deserialize, Clone, Debug)]
enum SortEvent {
    SortDidChanged,
    RowDidChanged(String),
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
