use crate::entities::{GroupRowsChangesetPB, InsertedRowPB, RowPB, SelectOptionGroupConfigurationPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{
    MultiSelectTypeOptionPB, SelectOptionCellDataPB, SelectOptionCellDataParser, SingleSelectTypeOptionPB,
};
use crate::services::group::{GenericGroupController, Group, GroupController, GroupGenerator, Groupable};

use flowy_grid_data_model::revision::{FieldRevision, RowRevision};

// SingleSelect
pub type SingleSelectGroupController = GenericGroupController<
    SelectOptionGroupConfigurationPB,
    SingleSelectTypeOptionPB,
    SingleSelectGroupGenerator,
    SelectOptionCellDataParser,
>;

impl Groupable for SingleSelectGroupController {
    type CellDataType = SelectOptionCellDataPB;
    fn can_group(&self, content: &str, cell_data: &SelectOptionCellDataPB) -> bool {
        cell_data.select_options.iter().any(|option| option.id == content)
    }

    fn group_row(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupRowsChangesetPB> {
        let mut changesets = vec![];
        self.groups_map.iter_mut().for_each(|(_, group): (_, &mut Group)| {
            group_select_option_row(group, &mut changesets, cell_data, row_rev);
        });
        changesets
    }
}

impl GroupController for SingleSelectGroupController {
    fn fill_row(&self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        let group: Option<&Group> = self.groups_map.get(group_id);
        match group {
            None => {}
            Some(group) => {
                let cell_rev = insert_select_option_cell(group.id.clone(), field_rev);
                row_rev.cells.insert(field_rev.id.clone(), cell_rev);
            }
        }
    }
}

pub struct SingleSelectGroupGenerator();
impl GroupGenerator for SingleSelectGroupGenerator {
    type ConfigurationType = SelectOptionGroupConfigurationPB;
    type TypeOptionType = SingleSelectTypeOptionPB;
    fn generate_groups(
        _configuration: &Option<Self::ConfigurationType>,
        type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<Group> {
        match type_option {
            None => vec![],
            Some(type_option) => type_option
                .options
                .iter()
                .map(|option| Group::new(option.id.clone(), option.name.clone(), option.id.clone()))
                .collect(),
        }
    }
}

// MultiSelect
pub type MultiSelectGroupController = GenericGroupController<
    SelectOptionGroupConfigurationPB,
    MultiSelectTypeOptionPB,
    MultiSelectGroupGenerator,
    SelectOptionCellDataParser,
>;

impl Groupable for MultiSelectGroupController {
    type CellDataType = SelectOptionCellDataPB;

    fn can_group(&self, content: &str, cell_data: &SelectOptionCellDataPB) -> bool {
        cell_data.select_options.iter().any(|option| option.id == content)
    }

    fn group_row(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupRowsChangesetPB> {
        let mut changesets = vec![];

        self.groups_map.iter_mut().for_each(|(_, group): (_, &mut Group)| {
            group_select_option_row(group, &mut changesets, cell_data, row_rev);
        });
        changesets
    }
}

impl GroupController for MultiSelectGroupController {
    fn fill_row(&self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        let group: Option<&Group> = self.groups_map.get(group_id);
        match group {
            None => tracing::warn!("Can not find the group: {}", group_id),
            Some(group) => {
                let cell_rev = insert_select_option_cell(group.id.clone(), field_rev);
                row_rev.cells.insert(field_rev.id.clone(), cell_rev);
            }
        }
    }
}

pub struct MultiSelectGroupGenerator();
impl GroupGenerator for MultiSelectGroupGenerator {
    type ConfigurationType = SelectOptionGroupConfigurationPB;
    type TypeOptionType = MultiSelectTypeOptionPB;

    fn generate_groups(
        _configuration: &Option<Self::ConfigurationType>,
        type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<Group> {
        match type_option {
            None => vec![],
            Some(type_option) => type_option
                .options
                .iter()
                .map(|option| Group::new(option.id.clone(), option.name.clone(), option.id.clone()))
                .collect(),
        }
    }
}

fn group_select_option_row(
    group: &mut Group,
    changesets: &mut Vec<GroupRowsChangesetPB>,
    cell_data: &SelectOptionCellDataPB,
    row_rev: &RowRevision,
) {
    cell_data.select_options.iter().for_each(|option| {
        if option.id == group.id {
            if !group.contains_row(&row_rev.id) {
                let row_pb = RowPB::from(row_rev);
                changesets.push(GroupRowsChangesetPB::insert(
                    group.id.clone(),
                    vec![InsertedRowPB::new(row_pb.clone())],
                ));
                group.add_row(row_pb);
            }
        } else if group.contains_row(&row_rev.id) {
            group.remove_row(&row_rev.id);
            changesets.push(GroupRowsChangesetPB::delete(group.id.clone(), vec![row_rev.id.clone()]));
        }
    });
}
