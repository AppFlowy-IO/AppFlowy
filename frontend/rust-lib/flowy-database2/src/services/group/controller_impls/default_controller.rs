use crate::entities::{GroupChangesetPB, RowPB};
use crate::services::group::action::{
  DidMoveGroupRowResult, DidUpdateGroupRowResult, GroupControllerActions,
};
use crate::services::group::{GroupController, GroupData, MoveGroupRowContext};
use collab_database::fields::Field;
use collab_database::rows::Row;

use flowy_error::FlowyResult;
use std::sync::Arc;

/// A [DefaultGroupController] is used to handle the group actions for the [FieldType] that doesn't
/// implement its own group controller. The default group controller only contains one group, which
/// means all rows will be grouped in the same group.
///
pub struct DefaultGroupController {
  pub field_id: String,
  pub group: GroupData,
}

const DEFAULT_GROUP_CONTROLLER: &str = "DefaultGroupController";

impl DefaultGroupController {
  pub fn new(field: &Arc<Field>) -> Self {
    let group = GroupData::new(
      DEFAULT_GROUP_CONTROLLER.to_owned(),
      field.id.clone(),
      "".to_owned(),
      "".to_owned(),
    );
    Self {
      field_id: field.id.clone(),
      group,
    }
  }
}

impl GroupControllerActions for DefaultGroupController {
  fn field_id(&self) -> &str {
    &self.field_id
  }

  fn groups(&self) -> Vec<&GroupData> {
    vec![&self.group]
  }

  fn get_group(&self, _group_id: &str) -> Option<(usize, GroupData)> {
    Some((0, self.group.clone()))
  }

  fn fill_groups(&mut self, rows: &[&Row], field: &Field) -> FlowyResult<()> {
    rows.iter().for_each(|row| {
      self.group.add_row(RowPB::from(*row));
    });
    Ok(())
  }

  fn move_group(&mut self, _from_group_id: &str, _to_group_id: &str) -> FlowyResult<()> {
    Ok(())
  }

  fn did_update_group_row(
    &mut self,
    old_row: &Option<Arc<Row>>,
    row: &Row,
    field: &Field,
  ) -> FlowyResult<DidUpdateGroupRowResult> {
    Ok(DidUpdateGroupRowResult {
      inserted_group: None,
      deleted_group: None,
      row_changesets: vec![],
    })
  }

  fn did_delete_delete_row(
    &mut self,
    row: &Row,
    field: &Field,
  ) -> FlowyResult<DidMoveGroupRowResult> {
    Ok(DidMoveGroupRowResult {
      deleted_group: None,
      row_changesets: vec![],
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

  fn did_update_group_field(&mut self, _field: &Field) -> FlowyResult<Option<GroupChangesetPB>> {
    Ok(None)
  }
}

impl GroupController for DefaultGroupController {
  fn will_create_row(&mut self, row: &mut Row, field: &Field, group_id: &str) {}

  fn did_create_row(&mut self, _row_rev: &RowPB, _group_id: &str) {}
}
