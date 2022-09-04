use crate::entities::GroupChangesetPB;
use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::action::GroupAction;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};

use crate::services::group::GeneratedGroup;
use flowy_grid_data_model::revision::{CheckboxGroupConfigurationRevision, FieldRevision, GroupRevision, RowRevision};

pub type CheckboxGroupController = GenericGroupController<
    CheckboxGroupConfigurationRevision,
    CheckboxTypeOptionPB,
    CheckboxGroupGenerator,
    CheckboxCellDataParser,
>;

pub type CheckboxGroupContext = GroupContext<CheckboxGroupConfigurationRevision>;

impl GroupAction for CheckboxGroupController {
    type CellDataType = CheckboxCellData;
    fn can_group(&self, _content: &str, _cell_data: &Self::CellDataType) -> bool {
        false
    }

    fn add_row_if_match(&mut self, _row_rev: &RowRevision, _cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        todo!()
    }

    fn remove_row_if_match(
        &mut self,
        _row_rev: &RowRevision,
        _cell_data: &Self::CellDataType,
    ) -> Vec<GroupChangesetPB> {
        todo!()
    }

    fn move_row(&mut self, _cell_data: &Self::CellDataType, _context: MoveGroupRowContext) -> Vec<GroupChangesetPB> {
        todo!()
    }
}

impl GroupController for CheckboxGroupController {
    fn will_create_row(&mut self, _row_rev: &mut RowRevision, _field_rev: &FieldRevision, _group_id: &str) {
        todo!()
    }
}

pub struct CheckboxGroupGenerator();
impl GroupGenerator for CheckboxGroupGenerator {
    type Context = CheckboxGroupContext;
    type TypeOptionType = CheckboxTypeOptionPB;

    fn generate_groups(
        _field_id: &str,
        _group_ctx: &Self::Context,
        _type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<GeneratedGroup> {
        let check_group = GeneratedGroup {
            group_rev: GroupRevision::new("true".to_string(), CHECK.to_string()),
            filter_content: "".to_string(),
        };

        let uncheck_group = GeneratedGroup {
            group_rev: GroupRevision::new("false".to_string(), UNCHECK.to_string()),
            filter_content: "".to_string(),
        };
        vec![check_group, uncheck_group]
    }
}
