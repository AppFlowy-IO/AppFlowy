use crate::entities::{GroupChangesetPB, GroupViewChangesetPB, RowPB};
use crate::services::group::{Group, GroupController, GroupControllerSharedOperation, MoveGroupRowContext};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use std::sync::Arc;

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
            "Oops".to_owned(),
            "".to_owned(),
        );
        Self {
            field_id: field_rev.id.clone(),
            group,
        }
    }
}

impl GroupControllerSharedOperation for DefaultGroupController {
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn groups(&self) -> Vec<Group> {
        vec![self.group.clone()]
    }

    fn get_group(&self, group_id: &str) -> Option<(usize, Group)> {
        Some((0, self.group.clone()))
    }

    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
        row_revs.iter().for_each(|row_rev| {
            self.group.add_row(RowPB::from(row_rev));
        });
        Ok(())
    }

    fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
        Ok(())
    }

    fn did_update_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>> {
        todo!()
    }

    fn did_delete_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>> {
        todo!()
    }

    fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<Vec<GroupChangesetPB>> {
        todo!()
    }

    fn did_update_field(&mut self, field_rev: &FieldRevision) -> FlowyResult<Option<GroupViewChangesetPB>> {
        Ok(None)
    }
}

impl GroupController for DefaultGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {}
}
