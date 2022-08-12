use crate::entities::SelectOptionGroupConfigurationPB;
use crate::services::cell::CellBytes;
use crate::services::field::{MultiSelectTypeOptionPB, SelectedSelectOptions, SingleSelectTypeOptionPB};
use crate::services::group::{Group, GroupAction, GroupCellContentProvider, GroupController, GroupGenerator};

pub type SingleSelectGroupController =
    GroupController<SelectOptionGroupConfigurationPB, SingleSelectTypeOptionPB, SingleSelectGroupGen>;

pub struct SingleSelectGroupGen();
impl GroupGenerator<SelectOptionGroupConfigurationPB, SingleSelectTypeOptionPB> for SingleSelectGroupGen {
    fn gen_groups(
        configuration: &Option<SelectOptionGroupConfigurationPB>,
        type_option: &Option<SingleSelectTypeOptionPB>,
        cell_content_provider: &dyn GroupCellContentProvider,
    ) -> Vec<Group> {
        todo!()
    }
}

impl GroupAction for SingleSelectGroupController {
    fn should_group(&mut self, content: &str, cell_bytes: CellBytes) -> bool {
        todo!()
    }
}

pub type MultiSelectGroupController =
    GroupController<SelectOptionGroupConfigurationPB, MultiSelectTypeOptionPB, MultiSelectGroupGen>;

pub struct MultiSelectGroupGen();
impl GroupGenerator<SelectOptionGroupConfigurationPB, MultiSelectTypeOptionPB> for MultiSelectGroupGen {
    fn gen_groups(
        configuration: &Option<SelectOptionGroupConfigurationPB>,
        type_option: &Option<MultiSelectTypeOptionPB>,
        cell_content_provider: &dyn GroupCellContentProvider,
    ) -> Vec<Group> {
        todo!()
    }
}

impl GroupAction for MultiSelectGroupController {
    fn should_group(&mut self, content: &str, cell_bytes: CellBytes) -> bool {
        todo!()
    }
}
