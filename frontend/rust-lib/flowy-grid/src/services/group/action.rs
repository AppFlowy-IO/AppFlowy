use crate::entities::GroupChangesetPB;

use crate::services::group::controller::MoveGroupRowContext;
use flowy_grid_data_model::revision::{CellRevision, RowRevision};

pub trait GroupAction: Send + Sync {
    type CellDataType;
    fn default_cell_rev(&self) -> Option<CellRevision> {
        None
    }

    fn can_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool;
    fn add_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB>;
    fn remove_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB>;
    fn move_row(&mut self, cell_data: &Self::CellDataType, context: MoveGroupRowContext) -> Vec<GroupChangesetPB>;
}
