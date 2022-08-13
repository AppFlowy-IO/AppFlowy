use crate::entities::{CheckboxGroupConfigurationPB, RowPB};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::RowRevision;

use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::{
    Group, GroupActionHandler, GroupCellContentProvider, GroupController, GroupGenerator, Groupable,
};

pub type CheckboxGroupController =
    GroupController<CheckboxGroupConfigurationPB, CheckboxTypeOptionPB, CheckboxGroupGenerator, CheckboxCellDataParser>;

impl Groupable for CheckboxGroupController {
    type CellDataType = CheckboxCellData;

    fn can_group(&self, _content: &str, _cell_data: &Self::CellDataType) -> bool {
        false
    }
}

impl GroupActionHandler for CheckboxGroupController {
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

pub struct CheckboxGroupGenerator();
impl GroupGenerator for CheckboxGroupGenerator {
    type ConfigurationType = CheckboxGroupConfigurationPB;
    type TypeOptionType = CheckboxTypeOptionPB;

    fn generate_groups(
        _configuration: &Option<Self::ConfigurationType>,
        _type_option: &Option<Self::TypeOptionType>,
        _cell_content_provider: &dyn GroupCellContentProvider,
    ) -> Vec<Group> {
        let check_group = Group {
            id: "true".to_string(),
            desc: "".to_string(),
            rows: vec![],
            content: CHECK.to_string(),
        };

        let uncheck_group = Group {
            id: "false".to_string(),
            desc: "".to_string(),
            rows: vec![],
            content: UNCHECK.to_string(),
        };

        vec![check_group, uncheck_group]
    }
}
