use crate::entities::SelectOptionGroupConfigurationPB;
use crate::services::cell::insert_select_option_cell;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};

use std::sync::Arc;

use crate::services::field::{
    MultiSelectTypeOptionPB, SelectOptionCellDataPB, SelectOptionCellDataParser, SingleSelectTypeOptionPB,
};
use crate::services::group::{
    Group, GroupActionHandler, GroupCellContentProvider, GroupController, GroupGenerator, Groupable,
};

// SingleSelect
pub type SingleSelectGroupController = GroupController<
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
}

impl GroupActionHandler for SingleSelectGroupController {
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn get_groups(&self) -> Vec<Group> {
        self.make_groups()
    }

    fn group_rows(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
        self.handle_rows(row_revs, field_rev)
    }

    fn update_card(&self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
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
        _cell_content_provider: &dyn GroupCellContentProvider,
    ) -> Vec<Group> {
        match type_option {
            None => vec![],
            Some(type_option) => type_option
                .options
                .iter()
                .map(|option| Group {
                    id: option.id.clone(),
                    desc: option.name.clone(),
                    rows: vec![],
                    content: option.id.clone(),
                })
                .collect(),
        }
    }
}

// MultiSelect
pub type MultiSelectGroupController = GroupController<
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
}

impl GroupActionHandler for MultiSelectGroupController {
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn get_groups(&self) -> Vec<Group> {
        self.make_groups()
    }

    fn group_rows(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
        self.handle_rows(row_revs, field_rev)
    }

    fn update_card(&self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
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
        _cell_content_provider: &dyn GroupCellContentProvider,
    ) -> Vec<Group> {
        match type_option {
            None => vec![],
            Some(type_option) => type_option
                .options
                .iter()
                .map(|option| Group {
                    id: option.id.clone(),
                    desc: option.name.clone(),
                    rows: vec![],
                    content: option.id.clone(),
                })
                .collect(),
        }
    }
}
