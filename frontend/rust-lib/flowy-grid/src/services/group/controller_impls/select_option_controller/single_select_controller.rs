use crate::entities::{GroupChangesetPB, RowPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{SelectOptionCellDataPB, SelectOptionCellDataParser, SingleSelectTypeOptionPB};
use crate::services::group::action::GroupAction;

use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};
use crate::services::group::controller_impls::select_option_controller::util::*;
use crate::services::group::entities::Group;

use crate::services::group::GeneratedGroup;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision, SelectOptionGroupConfigurationRevision};

// SingleSelect
pub type SingleSelectGroupController = GenericGroupController<
    SelectOptionGroupConfigurationRevision,
    SingleSelectTypeOptionPB,
    SingleSelectGroupGenerator,
    SelectOptionCellDataParser,
>;

impl GroupAction for SingleSelectGroupController {
    type CellDataType = SelectOptionCellDataPB;
    fn can_group(&self, content: &str, cell_data: &SelectOptionCellDataPB) -> bool {
        cell_data.select_options.iter().any(|option| option.id == content)
    }

    fn add_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_all_groups(|group| {
            if let Some(changeset) = add_select_option_row(group, cell_data, row_rev) {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn remove_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_all_groups(|group| {
            if let Some(changeset) = remove_select_option_row(group, cell_data, row_rev) {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn move_row(&mut self, _cell_data: &Self::CellDataType, mut context: MoveGroupRowContext) -> Vec<GroupChangesetPB> {
        let mut group_changeset = vec![];
        self.group_ctx.iter_mut_all_groups(|group| {
            if let Some(changeset) = move_group_row(group, &mut context) {
                group_changeset.push(changeset);
            }
        });
        group_changeset
    }
}

impl GroupController for SingleSelectGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        let group: Option<&mut Group> = self.group_ctx.get_mut_group(group_id);
        match group {
            None => {}
            Some(group) => {
                let cell_rev = insert_select_option_cell(vec![group.id.clone()], field_rev);
                row_rev.cells.insert(field_rev.id.clone(), cell_rev);
            }
        }
    }
    fn did_create_row(&mut self, row_pb: &RowPB, group_id: &str) {
        if let Some(group) = self.group_ctx.get_mut_group(group_id) {
            group.add_row(row_pb.clone())
        }
    }
}

pub struct SingleSelectGroupGenerator();
impl GroupGenerator for SingleSelectGroupGenerator {
    type Context = SelectOptionGroupContext;
    type TypeOptionType = SingleSelectTypeOptionPB;
    fn generate_groups(
        field_id: &str,
        group_ctx: &Self::Context,
        type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<GeneratedGroup> {
        match type_option {
            None => vec![],
            Some(type_option) => generate_select_option_groups(field_id, group_ctx, &type_option.options),
        }
    }
}
