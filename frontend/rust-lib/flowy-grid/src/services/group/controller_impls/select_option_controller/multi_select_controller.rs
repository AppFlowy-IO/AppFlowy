use crate::entities::GroupChangesetPB;
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{MultiSelectTypeOptionPB, SelectOptionCellDataPB, SelectOptionCellDataParser};
use crate::services::group::action::GroupAction;

use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};
use crate::services::group::controller_impls::select_option_controller::util::*;
use crate::services::group::entities::Group;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision, SelectOptionGroupConfigurationRevision};

// MultiSelect
pub type MultiSelectGroupController = GenericGroupController<
    SelectOptionGroupConfigurationRevision,
    MultiSelectTypeOptionPB,
    MultiSelectGroupGenerator,
    SelectOptionCellDataParser,
>;

impl GroupAction for MultiSelectGroupController {
    type CellDataType = SelectOptionCellDataPB;

    fn can_group(&self, content: &str, cell_data: &SelectOptionCellDataPB) -> bool {
        cell_data.select_options.iter().any(|option| option.id == content)
    }

    fn add_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.configuration.iter_mut_groups(|group| {
            if let Some(changeset) = add_row(group, cell_data, row_rev) {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn remove_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.configuration.iter_mut_groups(|group| {
            if let Some(changeset) = remove_row(group, cell_data, row_rev) {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn move_row(&mut self, cell_data: &Self::CellDataType, mut context: MoveGroupRowContext) -> Vec<GroupChangesetPB> {
        let mut group_changeset = vec![];
        self.configuration.iter_mut_groups(|group| {
            if let Some(changeset) = move_select_option_row(group, cell_data, &mut context) {
                group_changeset.push(changeset);
            }
        });
        group_changeset
    }
}

impl GroupController for MultiSelectGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        match self.configuration.get_group(group_id) {
            None => tracing::warn!("Can not find the group: {}", group_id),
            Some((_, group)) => {
                let cell_rev = insert_select_option_cell(group.id.clone(), field_rev);
                row_rev.cells.insert(field_rev.id.clone(), cell_rev);
            }
        }
    }
}

pub struct MultiSelectGroupGenerator();
impl GroupGenerator for MultiSelectGroupGenerator {
    type ConfigurationType = SelectOptionGroupConfiguration;
    type TypeOptionType = MultiSelectTypeOptionPB;
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
