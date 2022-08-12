use crate::entities::CheckboxGroupConfigurationPB;

use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::{Group, GroupAction, GroupCellContentProvider, GroupController, GroupGenerator};

pub type CheckboxGroupController =
    GroupController<CheckboxGroupConfigurationPB, CheckboxTypeOptionPB, CheckboxGroupGenerator, CheckboxCellDataParser>;

pub struct CheckboxGroupGenerator();
impl GroupGenerator for CheckboxGroupGenerator {
    type ConfigurationType = CheckboxGroupConfigurationPB;
    type TypeOptionType = CheckboxTypeOptionPB;

    fn gen_groups(
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

impl GroupAction for CheckboxGroupController {
    type CellDataType = CheckboxCellData;

    fn should_group(&self, _content: &str, _cell_data: &Self::CellDataType) -> bool {
        false
    }
}
