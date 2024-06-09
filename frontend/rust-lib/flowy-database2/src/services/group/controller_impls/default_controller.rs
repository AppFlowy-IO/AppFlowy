use std::sync::Arc;

use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cells, Row, RowDetail, RowId};

use flowy_error::FlowyResult;

use crate::entities::{
  GroupChangesPB, GroupPB, GroupRowsNotificationPB, InsertedGroupPB, InsertedRowPB,
};
use crate::services::group::action::{
  DidMoveGroupRowResult, DidUpdateGroupRowResult, GroupController,
};
use crate::services::group::{
  GroupChangeset, GroupControllerDelegate, GroupData, MoveGroupRowContext,
};

/// A [DefaultGroupController] is used to handle the group actions for the [FieldType] that doesn't
/// implement its own group controller. The default group controller only contains one group, which
/// means all rows will be grouped in the same group.
///
pub struct DefaultGroupController {
  pub field_id: String,
  pub group: GroupData,
  pub delegate: Arc<dyn GroupControllerDelegate>,
}

const DEFAULT_GROUP_CONTROLLER: &str = "DefaultGroupController";

impl DefaultGroupController {
  pub fn new(field: &Field, delegate: Arc<dyn GroupControllerDelegate>) -> Self {
    let group = GroupData::new(DEFAULT_GROUP_CONTROLLER.to_owned(), field.id.clone(), true);
    Self {
      field_id: field.id.clone(),
      group,
      delegate,
    }
  }
}

impl GroupController for DefaultGroupController {
  fn get_grouping_field_id(&self) -> &str {
    &self.field_id
  }

  fn get_all_groups(&self) -> Vec<&GroupData> {
    vec![&self.group]
  }

  fn get_group(&self, _group_id: &str) -> Option<(usize, GroupData)> {
    Some((0, self.group.clone()))
  }

  fn fill_groups(&mut self, rows: &[&RowDetail], _field: &Field) -> FlowyResult<()> {
    rows.iter().for_each(|row| {
      self.group.add_row((*row).clone());
    });
    Ok(())
  }

  fn create_group(
    &mut self,
    _name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)> {
    Ok((None, None))
  }

  fn move_group(&mut self, _from_group_id: &str, _to_group_id: &str) -> FlowyResult<()> {
    Ok(())
  }

  fn did_create_row(
    &mut self,
    row_detail: &RowDetail,
    index: usize,
  ) -> Vec<GroupRowsNotificationPB> {
    self.group.add_row((*row_detail).clone());

    vec![GroupRowsNotificationPB::insert(
      self.group.id.clone(),
      vec![InsertedRowPB {
        row_meta: (*row_detail).clone().into(),
        index: Some(index as i32),
        is_new: true,
      }],
    )]
  }

  fn did_update_group_row(
    &mut self,
    _old_row_detail: &Option<RowDetail>,
    _row_detail: &RowDetail,
    _field: &Field,
  ) -> FlowyResult<DidUpdateGroupRowResult> {
    Ok(DidUpdateGroupRowResult {
      inserted_group: None,
      deleted_group: None,
      row_changesets: vec![],
    })
  }

  fn did_delete_row(&mut self, row: &Row) -> FlowyResult<DidMoveGroupRowResult> {
    let mut changeset = GroupRowsNotificationPB::new(self.group.id.clone());
    if self.group.contains_row(&row.id) {
      self.group.remove_row(&row.id);
      changeset.deleted_rows.push(row.id.clone().into_inner());
    }
    Ok(DidMoveGroupRowResult {
      deleted_group: None,
      row_changesets: vec![changeset],
    })
  }

  fn move_group_row(
    &mut self,
    _context: MoveGroupRowContext,
  ) -> FlowyResult<DidMoveGroupRowResult> {
    Ok(DidMoveGroupRowResult {
      deleted_group: None,
      row_changesets: vec![],
    })
  }

  fn did_update_group_field(&mut self, _field: &Field) -> FlowyResult<Option<GroupChangesPB>> {
    Ok(None)
  }

  fn delete_group(&mut self, _group_id: &str) -> FlowyResult<(Vec<RowId>, Option<TypeOptionData>)> {
    Ok((vec![], None))
  }

  fn apply_group_changeset(
    &mut self,
    _changeset: &[GroupChangeset],
  ) -> FlowyResult<(Vec<GroupPB>, Option<TypeOptionData>)> {
    Ok((Vec::new(), None))
  }

  fn will_create_row(&self, _cells: &mut Cells, _field: &Field, _group_id: &str) {}
}
