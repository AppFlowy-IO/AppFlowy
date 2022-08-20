use crate::entities::{GroupRowsChangesetPB, RowPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{SelectOptionCellDataPB, SelectOptionCellDataParser, SingleSelectTypeOptionPB};
use crate::services::group::action::GroupAction;

use crate::services::group::controller::{GenericGroupController, GroupController, GroupGenerator};
use crate::services::group::controller_impls::select_option_controller::util::*;
use crate::services::group::entities::Group;

use flowy_grid_data_model::revision::{
    FieldRevision, RowChangeset, RowRevision, SelectOptionGroupConfigurationRevision,
};

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

    fn add_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupRowsChangesetPB> {
        let mut changesets = vec![];
        self.groups_map.iter_mut().for_each(|(_, group): (_, &mut Group)| {
            add_row(group, &mut changesets, cell_data, row_rev);
        });
        changesets
    }

    fn remove_row_if_match(
        &mut self,
        row_rev: &RowRevision,
        cell_data: &Self::CellDataType,
    ) -> Vec<GroupRowsChangesetPB> {
        let mut changesets = vec![];
        self.groups_map.iter_mut().for_each(|(_, group): (_, &mut Group)| {
            remove_row(group, &mut changesets, cell_data, row_rev);
        });
        changesets
    }

    fn move_row_if_match(
        &mut self,
        field_rev: &FieldRevision,
        row_rev: &RowRevision,
        row_changeset: &mut RowChangeset,
        cell_data: &Self::CellDataType,
        to_row_id: &str,
    ) -> Vec<GroupRowsChangesetPB> {
        let mut group_changeset = vec![];
        self.groups_map.iter_mut().for_each(|(_, group): (_, &mut Group)| {
            move_row(
                group,
                &mut group_changeset,
                field_rev,
                row_rev,
                row_changeset,
                cell_data,
                to_row_id,
            );
        });
        group_changeset
    }
}

impl GroupController for SingleSelectGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        let group: Option<&mut Group> = self.groups_map.get_mut(group_id);
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
