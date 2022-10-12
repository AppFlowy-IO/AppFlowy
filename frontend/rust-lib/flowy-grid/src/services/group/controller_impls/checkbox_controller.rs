use crate::entities::{GroupChangesetPB, InsertedRowPB, RowPB};
use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::action::GroupControllerCustomActions;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};

use crate::services::cell::insert_checkbox_cell;
use crate::services::group::{move_group_row, GeneratedGroupConfig, GeneratedGroupContext};
use flowy_grid_data_model::revision::{
    CellRevision, CheckboxGroupConfigurationRevision, FieldRevision, GroupRevision, RowRevision,
};

pub type CheckboxGroupController = GenericGroupController<
    CheckboxGroupConfigurationRevision,
    CheckboxTypeOptionPB,
    CheckboxGroupGenerator,
    CheckboxCellDataParser,
>;

pub type CheckboxGroupContext = GroupContext<CheckboxGroupConfigurationRevision>;

impl GroupControllerCustomActions for CheckboxGroupController {
    type CellDataType = CheckboxCellData;
    fn default_cell_rev(&self) -> Option<CellRevision> {
        Some(CellRevision::new(UNCHECK.to_string()))
    }

    fn can_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool {
        if cell_data.is_check() {
            content == CHECK
        } else {
            content == UNCHECK
        }
    }

    fn add_or_remove_row_in_groups_if_match(
        &mut self,
        row_rev: &RowRevision,
        cell_data: &Self::CellDataType,
    ) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_status_groups(|group| {
            let mut changeset = GroupChangesetPB::new(group.id.clone());
            let is_not_contained = !group.contains_row(&row_rev.id);
            if group.id == CHECK {
                if cell_data.is_uncheck() {
                    // Remove the row if the group.id is CHECK but the cell_data is UNCHECK
                    changeset.deleted_rows.push(row_rev.id.clone());
                    group.remove_row(&row_rev.id);
                } else {
                    // Add the row to the group if the group didn't contain the row
                    if is_not_contained {
                        let row_pb = RowPB::from(row_rev);
                        changeset.inserted_rows.push(InsertedRowPB::new(row_pb.clone()));
                        group.add_row(row_pb);
                    }
                }
            }

            if group.id == UNCHECK {
                if cell_data.is_check() {
                    // Remove the row if the group.id is UNCHECK but the cell_data is CHECK
                    changeset.deleted_rows.push(row_rev.id.clone());
                    group.remove_row(&row_rev.id);
                } else {
                    // Add the row to the group if the group didn't contain the row
                    if is_not_contained {
                        let row_pb = RowPB::from(row_rev);
                        changeset.inserted_rows.push(InsertedRowPB::new(row_pb.clone()));
                        group.add_row(row_pb);
                    }
                }
            }

            if !changeset.is_empty() {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn delete_row(&mut self, row_rev: &RowRevision, _cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_groups(|group| {
            let mut changeset = GroupChangesetPB::new(group.id.clone());
            if group.contains_row(&row_rev.id) {
                changeset.deleted_rows.push(row_rev.id.clone());
                group.remove_row(&row_rev.id);
            }

            if !changeset.is_empty() {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn move_row(&mut self, _cell_data: &Self::CellDataType, mut context: MoveGroupRowContext) -> Vec<GroupChangesetPB> {
        let mut group_changeset = vec![];
        self.group_ctx.iter_mut_groups(|group| {
            if let Some(changeset) = move_group_row(group, &mut context) {
                group_changeset.push(changeset);
            }
        });
        group_changeset
    }
}

impl GroupController for CheckboxGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        match self.group_ctx.get_group(group_id) {
            None => tracing::warn!("Can not find the group: {}", group_id),
            Some((_, group)) => {
                let is_check = group.id == CHECK;
                let cell_rev = insert_checkbox_cell(is_check, field_rev);
                row_rev.cells.insert(field_rev.id.clone(), cell_rev);
            }
        }
    }

    fn did_create_row(&mut self, row_pb: &RowPB, group_id: &str) {
        if let Some(group) = self.group_ctx.get_mut_group(group_id) {
            group.add_row(row_pb.clone())
        }
    }
}

pub struct CheckboxGroupGenerator();
impl GroupGenerator for CheckboxGroupGenerator {
    type Context = CheckboxGroupContext;
    type TypeOptionType = CheckboxTypeOptionPB;

    fn generate_groups(
        _field_rev: &FieldRevision,
        _group_ctx: &Self::Context,
        _type_option: &Option<Self::TypeOptionType>,
    ) -> GeneratedGroupContext {
        let check_group = GeneratedGroupConfig {
            group_rev: GroupRevision::new(CHECK.to_string(), "".to_string()),
            filter_content: CHECK.to_string(),
        };

        let uncheck_group = GeneratedGroupConfig {
            group_rev: GroupRevision::new(UNCHECK.to_string(), "".to_string()),
            filter_content: UNCHECK.to_string(),
        };

        GeneratedGroupContext {
            no_status_group: None,
            group_configs: vec![check_group, uncheck_group],
        }
    }
}
