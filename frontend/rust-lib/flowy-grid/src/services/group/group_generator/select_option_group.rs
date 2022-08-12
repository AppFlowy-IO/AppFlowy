use crate::entities::SelectOptionGroupConfigurationPB;
use crate::services::cell::CellBytes;
use crate::services::field::{
    MultiSelectTypeOptionPB, SelectOptionCellDataPB, SelectOptionCellDataParser, SelectedSelectOptions,
    SingleSelectTypeOptionPB,
};
use crate::services::group::{Group, GroupAction, GroupCellContentProvider, GroupController, GroupGenerator};
use std::collections::HashMap;

pub type SingleSelectGroupController = GroupController<
    SelectOptionGroupConfigurationPB,
    SingleSelectTypeOptionPB,
    SingleSelectGroupGenerator,
    SelectOptionCellDataParser,
>;

pub struct SingleSelectGroupGenerator();
impl GroupGenerator<SelectOptionGroupConfigurationPB, SingleSelectTypeOptionPB> for SingleSelectGroupGenerator {
    fn gen_groups(
        configuration: &Option<SelectOptionGroupConfigurationPB>,
        type_option: &Option<SingleSelectTypeOptionPB>,
        cell_content_provider: &dyn GroupCellContentProvider,
    ) -> HashMap<String, Group> {
        todo!()
    }
}

impl GroupAction<SelectOptionCellDataPB> for SingleSelectGroupController {
    fn should_group(&self, content: &str, cell_data: SelectOptionCellDataPB) -> bool {
        todo!()
    }
}

// pub type MultiSelectGroupController =
//     GroupController<SelectOptionGroupConfigurationPB, MultiSelectTypeOptionPB, MultiSelectGroupGenerator>;
//
// pub struct MultiSelectGroupGenerator();
// impl GroupGenerator<SelectOptionGroupConfigurationPB, MultiSelectTypeOptionPB> for MultiSelectGroupGenerator {
//     fn gen_groups(
//         configuration: &Option<SelectOptionGroupConfigurationPB>,
//         type_option: &Option<MultiSelectTypeOptionPB>,
//         cell_content_provider: &dyn GroupCellContentProvider,
//     ) -> HashMap<String, Group> {
//         todo!()
//     }
// }
//
// impl GroupAction for MultiSelectGroupController {
//     fn should_group(&self, content: &str, cell_bytes: CellBytes) -> bool {
//         todo!()
//     }
// }
