use crate::entities::{GroupRowsChangesetPB, InsertedRowPB, RowPB, SelectOptionGroupConfigurationPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{
    MultiSelectTypeOptionPB, SelectOptionCellDataPB, SelectOptionCellDataParser, SingleSelectTypeOptionPB,
};
use crate::services::group::{GenericGroupController, Group, GroupController, GroupGenerator, Groupable};

use flowy_grid_data_model::revision::{FieldRevision, RowChangeset, RowRevision};

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
    type ConfigurationType = SelectOptionGroupConfigurationPB;
    type TypeOptionType = SingleSelectTypeOptionPB;
    fn generate_groups(
        field_id: &str,
        _configuration: &Option<Self::ConfigurationType>,
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

impl GroupController for MultiSelectGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
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
        field_id: &str,
        _configuration: &Option<Self::ConfigurationType>,
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

fn add_row(
    group: &mut Group,
    changesets: &mut Vec<GroupRowsChangesetPB>,
    cell_data: &SelectOptionCellDataPB,
    row_rev: &RowRevision,
) {
    cell_data.select_options.iter().for_each(|option| {
        if option.id == group.id && !group.contains_row(&row_rev.id) {
            let row_pb = RowPB::from(row_rev);
            changesets.push(GroupRowsChangesetPB::insert(
                group.id.clone(),
                vec![InsertedRowPB::new(row_pb.clone())],
            ));
            group.add_row(row_pb);
        }
    });
}

fn remove_row(
    group: &mut Group,
    changesets: &mut Vec<GroupRowsChangesetPB>,
    cell_data: &SelectOptionCellDataPB,
    row_rev: &RowRevision,
) {
    cell_data.select_options.iter().for_each(|option| {
        if option.id == group.id && group.contains_row(&row_rev.id) {
            changesets.push(GroupRowsChangesetPB::delete(group.id.clone(), vec![row_rev.id.clone()]));
            group.remove_row(&row_rev.id);
        }
    });
}

fn move_row(
    group: &mut Group,
    group_changeset: &mut Vec<GroupRowsChangesetPB>,
    field_rev: &FieldRevision,
    row_rev: &RowRevision,
    row_changeset: &mut RowChangeset,
    cell_data: &SelectOptionCellDataPB,
    to_row_id: &str,
) {
    cell_data.select_options.iter().for_each(|option| {
        // Remove the row in which group contains the row
        let is_group_contains = group.contains_row(&row_rev.id);
        let to_index = group.index_of_row(to_row_id);

        if option.id == group.id && is_group_contains {
            group_changeset.push(GroupRowsChangesetPB::delete(group.id.clone(), vec![row_rev.id.clone()]));
            group.remove_row(&row_rev.id);
        }

        // Find the inserted group
        if let Some(to_index) = to_index {
            let row_pb = RowPB::from(row_rev);
            let inserted_row = InsertedRowPB {
                row: row_pb.clone(),
                index: Some(to_index as i32),
            };
            group_changeset.push(GroupRowsChangesetPB::insert(group.id.clone(), vec![inserted_row]));
            if group.number_of_row() == to_index {
                group.add_row(row_pb);
            } else {
                group.insert_row(to_index, row_pb);
            }
        }

        // If the inserted row comes from other group, it needs to update the corresponding cell content.
        if to_index.is_some() && option.id != group.id {
            // Update the corresponding row's cell content.
            let cell_rev = insert_select_option_cell(group.id.clone(), field_rev);
            row_changeset.cell_by_field_id.insert(field_rev.id.clone(), cell_rev);
        }
    });
}
