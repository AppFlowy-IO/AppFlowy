use crate::entities::SelectOptionGroupConfigurationPB;

use crate::services::field::{
    MultiSelectTypeOptionPB, SelectOptionCellDataPB, SelectOptionCellDataParser, SingleSelectTypeOptionPB,
};
use crate::services::group::{Group, GroupAction, GroupCellContentProvider, GroupController, GroupGenerator};

// SingleSelect
pub type SingleSelectGroupController = GroupController<
    SelectOptionGroupConfigurationPB,
    SingleSelectTypeOptionPB,
    SingleSelectGroupGenerator,
    SelectOptionCellDataParser,
>;

pub struct SingleSelectGroupGenerator();
impl GroupGenerator for SingleSelectGroupGenerator {
    type ConfigurationType = SelectOptionGroupConfigurationPB;
    type TypeOptionType = SingleSelectTypeOptionPB;
    fn gen_groups(
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

impl GroupAction for SingleSelectGroupController {
    type CellDataType = SelectOptionCellDataPB;
    fn should_group(&self, content: &str, cell_data: &SelectOptionCellDataPB) -> bool {
        cell_data.select_options.iter().any(|option| option.id == content)
    }
}

// MultiSelect
pub type MultiSelectGroupController = GroupController<
    SelectOptionGroupConfigurationPB,
    MultiSelectTypeOptionPB,
    MultiSelectGroupGenerator,
    SelectOptionCellDataParser,
>;

pub struct MultiSelectGroupGenerator();
impl GroupGenerator for MultiSelectGroupGenerator {
    type ConfigurationType = SelectOptionGroupConfigurationPB;
    type TypeOptionType = MultiSelectTypeOptionPB;

    fn gen_groups(
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

impl GroupAction for MultiSelectGroupController {
    type CellDataType = SelectOptionCellDataPB;
    fn should_group(&self, content: &str, cell_data: &SelectOptionCellDataPB) -> bool {
        cell_data.select_options.iter().any(|option| option.id == content)
    }
}
