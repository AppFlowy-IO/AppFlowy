#![allow(clippy::all)]

use crate::entities::FieldType;
#[allow(unused_attributes)]
use crate::entities::SortChangesetNotificationPB;
use crate::services::sort::{SortChangeset, SortType};
use flowy_task::TaskDispatcher;
use grid_rev_model::{CellRevision, FieldRevision, RowRevision, SortCondition, SortRevision};
use lib_infra::future::Fut;

use crate::services::cell::{AtomicCellDataCache, TypeCellData};
use crate::services::field::{default_order, TypeOptionCellExt};
use rayon::prelude::ParallelSliceMut;
use std::cmp::Ordering;

use std::sync::Arc;
use tokio::sync::RwLock;

pub trait SortDelegate: Send + Sync {
    fn get_sort_rev(&self, sort_type: SortType) -> Fut<Option<Arc<SortRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
}

pub struct SortController {
    handler_id: String,
    delegate: Box<dyn SortDelegate>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    sorts: Vec<Arc<SortRevision>>,
    cell_data_cache: AtomicCellDataCache,
}

impl SortController {
    pub fn new<T>(
        _view_id: &str,
        handler_id: &str,
        delegate: T,
        task_scheduler: Arc<RwLock<TaskDispatcher>>,
        cell_data_cache: AtomicCellDataCache,
    ) -> Self
    where
        T: SortDelegate + 'static,
    {
        Self {
            handler_id: handler_id.to_string(),
            delegate: Box::new(delegate),
            task_scheduler,
            sorts: vec![],
            cell_data_cache,
        }
    }

    pub async fn close(&self) {
        self.task_scheduler
            .write()
            .await
            .unregister_handler(&self.handler_id)
            .await;
    }

    pub async fn sort_rows(&self, rows: &mut Vec<Arc<RowRevision>>) {
        let field_revs = self.delegate.get_field_revs(None).await;
        rows.par_sort_by(|left, right| cmp_row(left, right, &self.sorts, &field_revs, &self.cell_data_cache));
    }

    #[tracing::instrument(level = "trace", skip(self))]
    pub async fn did_receive_changes(&mut self, changeset: SortChangeset) -> Option<SortChangesetNotificationPB> {
        if let Some(insert_sort) = changeset.insert_sort {
            if let Some(sort) = self.delegate.get_sort_rev(insert_sort).await {
                self.sorts.push(sort);
            }
        }

        if let Some(delete_sort_type) = changeset.delete_sort {
            if let Some(index) = self.sorts.iter().position(|sort| sort.id == delete_sort_type.sort_id) {
                self.sorts.remove(index);
            }
        }

        if let Some(_update_sort) = changeset.update_sort {
            //
        }

        None
    }
}

fn cmp_row(
    left: &Arc<RowRevision>,
    right: &Arc<RowRevision>,
    sorts: &[Arc<SortRevision>],
    field_revs: &[Arc<FieldRevision>],
    cell_data_cache: &AtomicCellDataCache,
) -> Ordering {
    let mut order = default_order();
    for sort in sorts.iter() {
        let cmp_order = match (left.cells.get(&sort.field_id), right.cells.get(&sort.field_id)) {
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

        if cmp_order.is_ne() {
            // If the cmp_order is not Ordering::Equal, then break the loop.
            order = match sort.condition {
                SortCondition::Ascending => cmp_order,
                SortCondition::Descending => cmp_order.reverse(),
            };
            break;
        }
    }
    order
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
