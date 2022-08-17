use crate::entities::CheckboxGroupConfigurationPB;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use std::sync::Arc;

use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::{Group, GroupActionHandler, GroupController, GroupGenerator, Groupable};

pub type CheckboxGroupController =
    GroupController<CheckboxGroupConfigurationPB, CheckboxTypeOptionPB, CheckboxGroupGenerator, CheckboxCellDataParser>;

impl Groupable for CheckboxGroupController {
    type CellDataType = CheckboxCellData;

    fn can_group(&self, _content: &str, _cell_data: &Self::CellDataType) -> bool {
        false
    }
}

impl GroupActionHandler for CheckboxGroupController {
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn build_groups(&self) -> Vec<Group> {
        self.make_groups()
    }

    fn group_rows(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
        self.handle_rows(row_revs, field_rev)
    }

    fn fill_row(&self, _row_rev: &mut RowRevision, _field_rev: &FieldRevision, _group_id: &str) {
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
