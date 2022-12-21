#![allow(clippy::all)]

use crate::entities::FieldType;
#[allow(unused_attributes)]
use crate::entities::SortChangesetNotificationPB;

use crate::services::sort::{SortChangeset, SortType};

use flowy_task::TaskDispatcher;
use grid_rev_model::{CellRevision, FieldRevision, RowRevision, SortCondition, SortRevision};
use lib_infra::future::Fut;

use std::cmp::Ordering;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait SortDelegate: Send + Sync {
    fn get_sort_rev(&self, sort_type: SortType) -> Fut<Vec<Arc<SortRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> Fut<Option<Arc<FieldRevision>>>;
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<FieldRevision>>>;
}

pub struct SortController {
    view_id: String,
    handler_id: String,
    delegate: Box<dyn SortDelegate>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    sorts: Vec<SortRevision>,
    row_orders: HashMap<String, usize>,
}

impl SortController {
    pub fn new<T>(view_id: &str, handler_id: &str, delegate: T, task_scheduler: Arc<RwLock<TaskDispatcher>>) -> Self
    where
        T: SortDelegate + 'static,
    {
        Self {
            view_id: view_id.to_string(),
            handler_id: handler_id.to_string(),
            delegate: Box::new(delegate),
            task_scheduler,
            sorts: vec![],
            row_orders: HashMap::new(),
        }
    }

    pub async fn close(&self) {
        self.task_scheduler
            .write()
            .await
            .unregister_handler(&self.handler_id)
            .await;
    }

    pub fn sort_rows(&self, _rows: &mut Vec<Arc<RowRevision>>) {
        // rows.par_sort_by(|left, right| cmp_row(left, right, &self.sorts));
    }

    pub async fn did_receive_changes(&mut self, _changeset: SortChangeset) -> Option<SortChangesetNotificationPB> {
        None
    }
}

#[allow(dead_code)]
fn cmp_row(
    left: &Arc<RowRevision>,
    right: &Arc<RowRevision>,
    sorts: &[SortRevision],
    field_revs: &[Arc<FieldRevision>],
) -> Ordering {
    let mut order = Ordering::Equal;
    for sort in sorts.iter() {
        let cmp_order = match (left.cells.get(&sort.field_id), right.cells.get(&sort.field_id)) {
            (Some(left_cell), Some(right_cell)) => {
                let field_type: FieldType = sort.field_type.into();
                match field_revs.iter().find(|field_rev| field_rev.id == sort.field_id) {
                    None => Ordering::Equal,
                    Some(field_rev) => cmp_cell(left_cell, right_cell, field_rev, field_type),
                }
            }
            (Some(_), None) => Ordering::Greater,
            (None, Some(_)) => Ordering::Less,
            _ => Ordering::Equal,
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

#[allow(dead_code)]
fn cmp_cell(
    _left: &CellRevision,
    _right: &CellRevision,
    _field_rev: &Arc<FieldRevision>,
    field_type: FieldType,
) -> Ordering {
    let cal_order = || {
        let order = match &field_type {
            // FieldType::RichText => {
            //     let left_cell = TypeCellData::try_from(left).ok()?.into();
            //     let right_cell = TypeCellData::try_from(right).ok()?.into();
            //     field_rev
            //         .get_type_option::<RichTextTypeOptionPB>(field_rev.ty)?
            //         .apply_cmp(&left_cell, &right_cell)
            // }
            // FieldType::Number => field_rev
            //     .get_type_option::<NumberTypeOptionPB>(field_rev.ty)?
            //     .apply_cmp(&left_cell, &right_cell),
            _ => Ordering::Equal,
        };
        Option::<Ordering>::Some(order)
    };

    cal_order().unwrap_or(Ordering::Equal)
}
