use crate::entities::{GroupChangesetPB, GroupViewChangesetPB, RowPB};
use crate::services::group::{Group, GroupController, GroupControllerSharedActions, MoveGroupRowContext};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use std::sync::Arc;

/// A [DefaultGroupController] is used to handle the group actions for the [FieldType] that doesn't
/// implement its own group controller. The default group controller only contains one group, which
/// means all rows will be grouped in the same group.
///
pub struct DefaultGroupController {
    pub field_id: String,
    pub group: Group,
}

const DEFAULT_GROUP_CONTROLLER: &str = "DefaultGroupController";

impl DefaultGroupController {
    pub fn new(field_rev: &Arc<FieldRevision>) -> Self {
        let group = Group::new(
            DEFAULT_GROUP_CONTROLLER.to_owned(),
            field_rev.id.clone(),
            "".to_owned(),
            "".to_owned(),
        );
        Self {
            field_id: field_rev.id.clone(),
            group,
        }
    }
}

impl GroupControllerSharedActions for DefaultGroupController {
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn groups(&self) -> Vec<Group> {
        vec![self.group.clone()]
    }

    fn get_group(&self, _group_id: &str) -> Option<(usize, Group)> {
        Some((0, self.group.clone()))
    }

    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], _field_rev: &FieldRevision) -> FlowyResult<()> {
        row_revs.iter().for_each(|row_rev| {
            self.group.add_row(RowPB::from(row_rev));
        });
        Ok(())
    }

    fn move_group(&mut self, _from_group_id: &str, _to_group_id: &str) -> FlowyResult<()> {
        Ok(())
    }

    fn did_update_group_row(
        &mut self,
        _row_rev: &RowRevision,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>> {
        Ok(vec![])
    }

    fn did_delete_delete_row(
        &mut self,
        _row_rev: &RowRevision,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>> {
        Ok(vec![])
    }

    fn move_group_row(&mut self, _context: MoveGroupRowContext) -> FlowyResult<Vec<GroupChangesetPB>> {
        todo!()
    }

    fn did_update_group_field(&mut self, _field_rev: &FieldRevision) -> FlowyResult<Option<GroupViewChangesetPB>> {
        Ok(None)
    }
}

impl GroupController for DefaultGroupController {
    fn will_create_row(&mut self, _row_rev: &mut RowRevision, _field_rev: &FieldRevision, _group_id: &str) {}

    fn did_create_row(&mut self, _row_rev: &RowPB, _group_id: &str) {}
}
