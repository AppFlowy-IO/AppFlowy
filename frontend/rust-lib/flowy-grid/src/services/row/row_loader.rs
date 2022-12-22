use crate::entities::RowPB;
use grid_rev_model::RowRevision;

use std::sync::Arc;

pub struct GridBlockRowRevision {
    pub(crate) block_id: String,
    pub row_revs: Vec<Arc<RowRevision>>,
}

pub struct GridBlockRow {
    pub block_id: String,
    pub row_ids: Vec<String>,
}

impl GridBlockRow {
    pub fn new(block_id: String, row_ids: Vec<String>) -> Self {
        Self { block_id, row_ids }
    }
}

pub(crate) fn make_row_from_row_rev(row_rev: Arc<RowRevision>) -> RowPB {
    make_rows_from_row_revs(&[row_rev]).pop().unwrap()
}

pub(crate) fn make_rows_from_row_revs(row_revs: &[Arc<RowRevision>]) -> Vec<RowPB> {
    let make_row = |row_rev: &Arc<RowRevision>| RowPB {
        block_id: row_rev.block_id.clone(),
        id: row_rev.id.clone(),
        height: row_rev.height,
    };

    row_revs.iter().map(make_row).collect::<Vec<_>>()
}
