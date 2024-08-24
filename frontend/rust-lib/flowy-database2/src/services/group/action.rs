use async_trait::async_trait;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, Cells, Row, RowDetail, RowId};

use flowy_error::FlowyResult;

use crate::entities::{GroupChangesPB, GroupPB, GroupRowsNotificationPB, InsertedGroupPB};
use crate::services::field::TypeOption;
use crate::services::group::{GroupChangeset, GroupData, MoveGroupRowContext};

/// [GroupCustomize] is implemented by parameterized `BaseGroupController`s to provide different
/// behaviors. This allows the BaseGroupController to call these actions indescriminantly using
/// polymorphism.
#[async_trait]
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
  fn move_row(&mut self, context: MoveGroupRowContext) -> Vec<GroupRowsNotificationPB>;

  /// Returns None if there is no need to delete the group when corresponding row get removed
  fn delete_group_when_move_row(
    &mut self,
    _row: &Row,
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Option<GroupPB> {
    None
  }

  async fn create_group(
    &mut self,
    _name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)> {
    Ok((None, None))
  }

  async fn delete_group(&mut self, group_id: &str) -> FlowyResult<Option<TypeOptionData>>;

  fn update_type_option_when_update_group(
    &mut self,
    _changeset: &GroupChangeset,
    _type_option: &Self::GroupTypeOption,
  ) -> Option<Self::GroupTypeOption> {
    None
  }

  fn will_create_row(&self, cells: &mut Cells, field: &Field, group_id: &str);
}

/// The `GroupController` trait defines the behavior of the group controller when performing any
/// group-related tasks, such as managing rows within a group, transferring rows between groups,
/// manipulating groups themselves, and even pre-filling a row's cells before it is created.
///
/// Depending on the type of the field that is being grouped, a parameterized `BaseGroupController`
/// or a `DefaultGroupController` may be the actual object that provides the functionality of
/// this trait. For example, a `Single-Select` group controller will be a `BaseGroupController`,
/// while a `URL` group controller will be a `DefaultGroupController`.
#[async_trait]
pub trait GroupController: Send + Sync {
  /// Returns the id of field that is being used to group the rows
  fn get_grouping_field_id(&self) -> &str;

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
  async fn create_group(
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
  async fn delete_group(
    &mut self,
    group_id: &str,
  ) -> FlowyResult<(Vec<RowId>, Option<TypeOptionData>)>;

  /// Updates the name and/or visibility of groups.
  ///
  /// Returns a non-empty `TypeOptionData` when the changes require a change
  /// in the field type option data.
  ///
  /// * `changesets`: list of changesets to be made to one or more groups
  async fn apply_group_changeset(
    &mut self,
    changesets: &[GroupChangeset],
  ) -> FlowyResult<(Vec<GroupPB>, Option<TypeOptionData>)>;

  /// Called before the row was created.
  fn will_create_row(&self, cells: &mut Cells, field: &Field, group_id: &str);
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
