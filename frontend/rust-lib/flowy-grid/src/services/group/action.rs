use crate::entities::{GroupChangesetPB, GroupViewChangesetPB};
use crate::services::cell::CellDataIsEmpty;
use crate::services::group::controller::MoveGroupRowContext;
use crate::services::group::Group;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, RowRevision};
use std::sync::Arc;

/// Using polymorphism to provides the customs action for different group controller.
///
/// For example, the `CheckboxGroupController` implements this trait to provide custom behavior.
///
pub trait GroupControllerCustomActions: Send + Sync {
    type CellDataType: CellDataIsEmpty;
    /// Returns the a value of the cell, default value is None
    ///
    /// Determine which group the row is placed in based on the data of the cell. If the cell data
    /// is None. The row will be put in to the `No status` group  
    ///
    fn default_cell_rev(&self) -> Option<CellRevision> {
        None
    }

    /// Returns a bool value to determine whether the group should contain this cell or not.
    fn can_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool;

    /// Adds or removes a row if the cell data match the group filter.
    /// It gets called after editing the cell or row
    ///
    fn add_or_remove_row_in_groups_if_match(
        &mut self,
        row_rev: &RowRevision,
        cell_data: &Self::CellDataType,
    ) -> Vec<GroupChangesetPB>;

    /// Deletes the row from the group
    fn delete_row(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB>;

    /// Move row from one group to another
    fn move_row(&mut self, cell_data: &Self::CellDataType, context: MoveGroupRowContext) -> Vec<GroupChangesetPB>;
}

/// Defines the shared actions any group controller can perform.
pub trait GroupControllerSharedActions: Send + Sync {
    /// The field that is used for grouping the rows
    fn field_id(&self) -> &str;

    /// Returns number of groups the current field has
    fn groups(&self) -> Vec<Group>;

    /// Returns the index and the group data with group_id
    fn get_group(&self, group_id: &str) -> Option<(usize, Group)>;

    /// Separates the rows into different groups
    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()>;

    /// Remove the group with from_group_id and insert it to the index with to_group_id
    fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()>;

    /// Insert/Remove the row to the group if the corresponding cell data is changed
    fn did_update_group_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>>;

    /// Remove the row from the group if the row gets deleted
    fn did_delete_delete_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>>;

    /// Move the row from one group to another group
    fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<Vec<GroupChangesetPB>>;

    /// Update the group if the corresponding field is changed
    fn did_update_group_field(&mut self, field_rev: &FieldRevision) -> FlowyResult<Option<GroupViewChangesetPB>>;
}
