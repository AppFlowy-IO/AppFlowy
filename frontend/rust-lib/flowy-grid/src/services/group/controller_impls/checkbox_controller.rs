use crate::entities::GroupRowsChangesetPB;
use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::action::GroupAction;
use crate::services::group::configuration::GenericGroupConfiguration;
use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};
use crate::services::group::entities::Group;

use flowy_grid_data_model::revision::{CheckboxGroupConfigurationRevision, FieldRevision, RowRevision};

pub type CheckboxGroupController = GenericGroupController<
    CheckboxGroupConfigurationRevision,
    CheckboxTypeOptionPB,
    CheckboxGroupGenerator,
    CheckboxCellDataParser,
>;

pub type CheckboxGroupConfiguration = GenericGroupConfiguration<CheckboxGroupConfigurationRevision>;

impl GroupAction for CheckboxGroupController {
    type CellDataType = CheckboxCellData;
    fn can_group(&self, _content: &str, _cell_data: &Self::CellDataType) -> bool {
        false
    }

    fn add_row_if_match(
        &mut self,
        _row_rev: &RowRevision,
        _cell_data: &Self::CellDataType,
    ) -> Vec<GroupRowsChangesetPB> {
        todo!()
    }

    fn remove_row_if_match(
        &mut self,
        _row_rev: &RowRevision,
        _cell_data: &Self::CellDataType,
    ) -> Vec<GroupRowsChangesetPB> {
        todo!()
    }

    fn move_row(
        &mut self,
        _cell_data: &Self::CellDataType,
        _context: MoveGroupRowContext,
    ) -> Vec<GroupRowsChangesetPB> {
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
    type ConfigurationType = CheckboxGroupConfiguration;
    type TypeOptionType = CheckboxTypeOptionPB;

    fn generate_groups(
        field_id: &str,
        _configuration: &Self::ConfigurationType,
        _type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<Group> {
        let check_group = Group::new(
            "true".to_string(),
            field_id.to_owned(),
            "".to_string(),
            CHECK.to_string(),
        );
        let uncheck_group = Group::new(
            "false".to_string(),
            field_id.to_owned(),
            "".to_string(),
            UNCHECK.to_string(),
        );
        vec![check_group, uncheck_group]
    }
}
