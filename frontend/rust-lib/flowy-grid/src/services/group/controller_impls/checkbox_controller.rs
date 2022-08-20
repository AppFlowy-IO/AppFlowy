use crate::entities::GroupRowsChangesetPB;
use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::action::GroupAction;
use crate::services::group::configuration::{GenericGroupConfiguration, GroupConfigurationAction};
use crate::services::group::entities::Group;
use crate::services::group::group_controller::{GenericGroupController, GroupController, GroupGenerator};
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    CheckboxGroupConfigurationRevision, FieldRevision, GroupRecordRevision, RowChangeset, RowRevision,
};

pub type CheckboxGroupController = GenericGroupController<
    CheckboxGroupConfigurationRevision,
    CheckboxTypeOptionPB,
    CheckboxGroupGenerator,
    CheckboxCellDataParser,
>;

pub type CheckboxGroupConfiguration = GenericGroupConfiguration<CheckboxGroupConfigurationRevision>;
impl GroupConfigurationAction for CheckboxGroupConfiguration {
    fn group_records(&self) -> &[GroupRecordRevision] {
        &[]
    }

    fn merge_groups(&self, groups: Vec<Group>) -> FlowyResult<()> {
        Ok(())
    }

    fn hide_group(&self, group_id: &str) -> FlowyResult<()> {
        Ok(())
    }

    fn show_group(&self, group_id: &str) -> FlowyResult<()> {
        Ok(())
    }
}

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

    fn move_row_if_match(
        &mut self,
        _field_rev: &FieldRevision,
        _row_rev: &RowRevision,
        _row_changeset: &mut RowChangeset,
        _cell_data: &Self::CellDataType,
        _to_row_id: &str,
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
        configuration: &Self::ConfigurationType,
        type_option: &Option<Self::TypeOptionType>,
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
