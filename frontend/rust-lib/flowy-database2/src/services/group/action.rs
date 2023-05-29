use crate::entities::{GroupChangesPB, GroupPB, GroupRowsNotificationPB, InsertedGroupPB};
use crate::services::cell::DecodedCellData;
use crate::services::group::controller::MoveGroupRowContext;
use crate::services::group::{GroupData, GroupSettingChangeset};
use collab_database::fields::Field;
use collab_database::rows::{Cell, Row};

use flowy_error::FlowyResult;

/// Using polymorphism to provides the customs action for different group controller.
///
/// For example, the `CheckboxGroupController` implements this trait to provide custom behavior.
///
pub trait GroupCustomize: Send + Sync {
  type CellData: DecodedCellData;
  /// Returns the a value of the cell if the cell data is not exist.
  /// The default value is `None`
  ///
  /// Determine which group the row is placed in based on the data of the cell. If the cell data
  /// is None. The row will be put in to the `No status` group  
  ///
  fn placeholder_cell(&self) -> Option<Cell> {
    None
  }

  /// Returns a bool value to determine whether the group should contain this cell or not.
  fn can_group(&self, content: &str, cell_data: &Self::CellData) -> bool;

  fn create_or_delete_group_when_cell_changed(
    &mut self,
    _row: &Row,
    _old_cell_data: Option<&Self::CellData>,
    _cell_data: &Self::CellData,
  ) -> FlowyResult<(Option<InsertedGroupPB>, Option<GroupPB>)> {
    Ok((None, None))
  }

  /// Adds or removes a row if the cell data match the group filter.
  /// It gets called after editing the cell or row
  ///
  fn add_or_remove_row_when_cell_changed(
    &mut self,
    row: &Row,
    cell_data: &Self::CellData,
  ) -> Vec<GroupRowsNotificationPB>;

  /// Deletes the row from the group
  fn delete_row(&mut self, row: &Row, cell_data: &Self::CellData) -> Vec<GroupRowsNotificationPB>;

  /// Move row from one group to another
  fn move_row(
    &mut self,
    cell_data: &Self::CellData,
    context: MoveGroupRowContext,
  ) -> Vec<GroupRowsNotificationPB>;

  /// Returns None if there is no need to delete the group when corresponding row get removed
  fn delete_group_when_move_row(
    &mut self,
    _row: &Row,
    _cell_data: &Self::CellData,
  ) -> Option<GroupPB> {
    None
  }
}

/// Defines the shared actions any group controller can perform.
pub trait GroupControllerOperation: Send + Sync {
  /// The field that is used for grouping the rows
  fn field_id(&self) -> &str;

  /// Returns number of groups the current field has
  fn groups(&self) -> Vec<&GroupData>;

  /// Returns the index and the group data with group_id
  fn get_group(&self, group_id: &str) -> Option<(usize, GroupData)>;

  /// Separates the rows into different groups
  fn fill_groups(&mut self, rows: &[&Row], field: &Field) -> FlowyResult<()>;

  /// Remove the group with from_group_id and insert it to the index with to_group_id
  fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()>;

  /// Insert/Remove the row to the group if the corresponding cell data is changed
  fn did_update_group_row(
    &mut self,
    old_row: &Option<Row>,
    row: &Row,
    field: &Field,
  ) -> FlowyResult<DidUpdateGroupRowResult>;

  /// Remove the row from the group if the row gets deleted
  fn did_delete_delete_row(
    &mut self,
    row: &Row,
    field: &Field,
  ) -> FlowyResult<DidMoveGroupRowResult>;

  /// Move the row from one group to another group
  fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<DidMoveGroupRowResult>;

  /// Update the group if the corresponding field is changed
  fn did_update_group_field(&mut self, field: &Field) -> FlowyResult<Option<GroupChangesPB>>;

  fn apply_group_setting_changeset(&mut self, changeset: GroupSettingChangeset) -> FlowyResult<()>;
}

#[derive(Debug)]
pub struct DidUpdateGroupRowResult {
  pub(crate) inserted_group: Option<InsertedGroupPB>,
  pub(crate) deleted_group: Option<GroupPB>,
  pub(crate) row_changesets: Vec<GroupRowsNotificationPB>,
}

#[derive(Debug)]
pub struct DidMoveGroupRowResult {
  pub(crate) deleted_group: Option<GroupPB>,
  pub(crate) row_changesets: Vec<GroupRowsNotificationPB>,
}
