use crate::entities::{GroupChangesetPB, RowPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{SelectOptionCellDataPB, SelectOptionCellDataParser, SingleSelectTypeOptionPB};
use crate::services::group::action::GroupAction;

use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};
use crate::services::group::controller_impls::select_option_controller::util::*;
use crate::services::group::entities::Group;

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
        self.configuration.with_mut_groups(|group| {
            add_row(group, &mut changesets, cell_data, row_rev);
        });
        changesets
    }

    fn remove_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.configuration.with_mut_groups(|group| {
            remove_row(group, &mut changesets, cell_data, row_rev);
        });
        changesets
    }

    fn move_row(&mut self, cell_data: &Self::CellDataType, mut context: MoveGroupRowContext) -> Vec<GroupChangesetPB> {
        let mut group_changeset = vec![];
        self.configuration.with_mut_groups(|group| {
            move_select_option_row(group, &mut group_changeset, cell_data, &mut context);
        });
        group_changeset
    }
}

impl GroupController for SingleSelectGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        let group: Option<&mut Group> = self.configuration.get_mut_group(group_id);
        match group {
            None => {}
            Some(group) => {
                let cell_rev = insert_select_option_cell(group.id.clone(), field_rev);
                row_rev.cells.insert(field_rev.id.clone(), cell_rev);
                group.add_row(RowPB::from(row_rev));
            }
        }
    }
}

pub struct SingleSelectGroupGenerator();
impl GroupGenerator for SingleSelectGroupGenerator {
    type ConfigurationType = SelectOptionGroupConfiguration;
    type TypeOptionType = SingleSelectTypeOptionPB;
    fn generate_groups(
        field_id: &str,
        _configuration: &Self::ConfigurationType,
        type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<Group> {
        match type_option {
            None => vec![],
            Some(type_option) => type_option
                .options
                .iter()
                .map(|option| {
                    Group::new(
                        option.id.clone(),
                        field_id.to_owned(),
                        option.name.clone(),
                        option.id.clone(),
                    )
                })
                .collect(),
        }
    }
}
