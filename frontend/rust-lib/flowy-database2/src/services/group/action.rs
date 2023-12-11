use async_trait::async_trait;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, Row, RowDetail, RowId};

use flowy_error::FlowyResult;

use crate::entities::{GroupChangesPB, GroupPB, GroupRowsNotificationPB, InsertedGroupPB};
use crate::services::field::TypeOption;
use crate::services::group::{GroupChangesets, GroupData, MoveGroupRowContext};

/// Using polymorphism to provides the customs action for different group controller.
///
/// For example, the `CheckboxGroupController` implements this trait to provide custom behavior.
///
pub trait GroupCustomize: Send + Sync {
  type GroupTypeOption: TypeOption;
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
  fn can_group(
    &self,
    content: &str,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> bool;

  fn create_or_delete_group_when_cell_changed(
    &mut self,
    _row_detail: &RowDetail,
    _old_cell_data: Option<&<Self::GroupTypeOption as TypeOption>::CellProtobufType>,
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> FlowyResult<(Option<InsertedGroupPB>, Option<GroupPB>)> {
    Ok((None, None))
  }

  /// Adds or removes a row if the cell data match the group filter.
  /// It gets called after editing the cell or row
  ///
  fn add_or_remove_row_when_cell_changed(
    &mut self,
    row_detail: &RowDetail,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Vec<GroupRowsNotificationPB>;

  /// Deletes the row from the group
  fn delete_row(
    &mut self,
    row: &Row,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> (Option<GroupPB>, Vec<GroupRowsNotificationPB>);

  /// Move row from one group to another
  fn move_row(
    &mut self,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
    context: MoveGroupRowContext,
  ) -> Vec<GroupRowsNotificationPB>;

  /// Returns None if there is no need to delete the group when corresponding row get removed
  fn delete_group_when_move_row(
    &mut self,
    _row: &Row,
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Option<GroupPB> {
    None
  }

  fn generate_new_group(
    &mut self,
    _name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)> {
    Ok((None, None))
  }

  fn delete_group_custom(&mut self, group_id: &str) -> FlowyResult<Option<TypeOptionData>>;
}

/// Defines the shared actions any group controller can perform.
#[async_trait]
pub trait GroupControllerOperation: Send + Sync {
  /// Returns the id of field that is being used to group the rows
  fn field_id(&self) -> &str;

  /// Returns all of the groups currently managed by the controller
  fn get_all_groups(&self) -> Vec<&GroupData>;

  /// Returns the index and the group data with the given group id if it exists.
  ///
  /// * `group_id` - A string slice that is used to match the group
  fn get_group(&self, group_id: &str) -> Option<(usize, GroupData)>;

  /// Sort the rows into the different groups.
  ///
  /// * `rows`: rows to be inserted
  /// * `field`: reference to the field being sorted (currently unused)
  fn fill_groups(&mut self, rows: &[&RowDetail], field: &Field) -> FlowyResult<()>;

  /// Create a new group, currently only supports single and multi-select.
  ///
  /// Returns a new type option data for the grouping field if it's altered.
  ///
  /// * `name`: name of the new group
  fn create_group(
    &mut self,
    name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)>;

  /// Reorders the group in the group controller.
  ///
  /// * `from_group_id`: id of the group being moved
  /// * `to_group_id`: id of the group whose index is the one at which the
  /// reordered group will be placed
  fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()>;

  /// Adds a newly-created row to one or more suitable groups.
  ///
  /// Returns a changeset payload to be sent as a notification.
  ///
  /// * `row_detail`: the newly-created row
  fn did_create_row(
    &mut self,
    row_detail: &RowDetail,
    index: usize,
  ) -> Vec<GroupRowsNotificationPB>;

  /// Called after a row's cell data is changed, this moves the row to the
  /// correct group. It may also insert a new group and/or remove an old group.
  ///
  /// Returns the inserted and removed groups if necessary for notification.
  ///
  /// * `old_row_detail`:
  /// * `row_detail`:
  /// * `field`:
  fn did_update_group_row(
    &mut self,
    old_row_detail: &Option<RowDetail>,
    row_detail: &RowDetail,
    field: &Field,
  ) -> FlowyResult<DidUpdateGroupRowResult>;

  /// Called after the row is deleted, this removes the row from the group.
  /// A group could be deleted as a result.
  ///
  /// Returns a the removed group when this occurs.
  fn did_delete_row(&mut self, row: &Row) -> FlowyResult<DidMoveGroupRowResult>;

  /// Reorders a row within the current group or move the row to another group.
  ///
  /// * `context`: information about the row being moved and its destination
  fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<DidMoveGroupRowResult>;

  /// Updates the groups after a field change. (currently never does anything)
  ///
  /// * `field`: new changeset
  fn did_update_group_field(&mut self, field: &Field) -> FlowyResult<Option<GroupChangesPB>>;

  /// Delete a group from the group configuration.
  ///
  /// Return a list of deleted row ids and/or a new `TypeOptionData` if
  /// successful.
  ///
  /// * `group_id`: the id of the group to be deleted
  fn delete_group(&mut self, group_id: &str) -> FlowyResult<(Vec<RowId>, Option<TypeOptionData>)>;

  /// Updates the name and/or visibility of groups.
  ///
  /// Returns a non-empty `TypeOptionData` when the changes require a change
  /// in the field type option data.
  ///
  /// * `changesets`: list of changesets to be made to one or more groups
  async fn apply_group_changeset(
    &mut self,
    changesets: &GroupChangesets,
  ) -> FlowyResult<(Vec<GroupPB>, TypeOptionData)>;
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
