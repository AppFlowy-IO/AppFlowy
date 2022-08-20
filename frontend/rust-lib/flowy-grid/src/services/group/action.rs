use crate::entities::GroupRowsChangesetPB;

use flowy_grid_data_model::revision::{FieldRevision, RowChangeset, RowRevision};

pub trait GroupAction: Send + Sync {
    type CellDataType;
    fn can_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool;
    fn add_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupRowsChangesetPB>;
    fn remove_row_if_match(
        &mut self,
        row_rev: &RowRevision,
        cell_data: &Self::CellDataType,
    ) -> Vec<GroupRowsChangesetPB>;

    fn move_row_if_match(
        &mut self,
        field_rev: &FieldRevision,
        row_rev: &RowRevision,
        row_changeset: &mut RowChangeset,
        cell_data: &Self::CellDataType,
        to_row_id: &str,
    ) -> Vec<GroupRowsChangesetPB>;
}
