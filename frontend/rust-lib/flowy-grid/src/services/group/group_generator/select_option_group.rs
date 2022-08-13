use crate::entities::{RowPB, SelectOptionGroupConfigurationPB};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::RowRevision;

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
    fn get_groups(&self) -> Vec<Group> {
        self.groups()
    }

    fn group_row(&mut self, row_rev: &RowRevision) -> FlowyResult<()> {
        self.handle_row(row_rev)
    }

    fn create_card(&self, row_rev: &mut RowRevision) {
        todo!()
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
    fn get_groups(&self) -> Vec<Group> {
        self.groups()
    }

    fn group_row(&mut self, row_rev: &RowRevision) -> FlowyResult<()> {
        self.handle_row(row_rev)
    }

    fn create_card(&self, row_rev: &mut RowRevision) {
        todo!()
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
