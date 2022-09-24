use crate::entities::{GroupChangesetPB, InsertedRowPB, RowPB};
use crate::services::field::{CheckboxCellData, CheckboxCellDataParser, CheckboxTypeOptionPB, CHECK, UNCHECK};
use crate::services::group::action::GroupAction;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};

use crate::services::cell::insert_checkbox_cell;
use crate::services::group::{move_group_row, GeneratedGroup};
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

impl GroupAction for CheckboxGroupController {
    type CellDataType = CheckboxCellData;
    fn default_cell_rev(&self) -> Option<CellRevision> {
        Some(CellRevision::new(UNCHECK.to_string()))
    }

    fn use_default_group(&self) -> bool {
        false
    }

    fn can_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool {
        if cell_data.is_check() {
            content == CHECK
        } else {
            content == UNCHECK
        }
    }

    fn add_row_if_match(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_all_groups(|group| {
            let mut changeset = GroupChangesetPB::new(group.id.clone());
            let is_contained = group.contains_row(&row_rev.id);
            if group.id == CHECK && cell_data.is_check() {
                if !is_contained {
                    let row_pb = RowPB::from(row_rev);
                    changeset.inserted_rows.push(InsertedRowPB::new(row_pb.clone()));
                    group.add_row(row_pb);
                }
            } else if is_contained {
                changeset.deleted_rows.push(row_rev.id.clone());
                group.remove_row(&row_rev.id);
            }
            if !changeset.is_empty() {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn remove_row_if_match(&mut self, row_rev: &RowRevision, _cell_data: &Self::CellDataType) -> Vec<GroupChangesetPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_all_groups(|group| {
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
        self.group_ctx.iter_mut_all_groups(|group| {
            if let Some(changeset) = move_group_row(group,  &mut context) {
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
        _field_id: &str,
        _group_ctx: &Self::Context,
        _type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<GeneratedGroup> {
        let check_group = GeneratedGroup {
            group_rev: GroupRevision::new(CHECK.to_string(), "".to_string()),
            filter_content: CHECK.to_string(),
        };

        let uncheck_group = GeneratedGroup {
            group_rev: GroupRevision::new(UNCHECK.to_string(), "".to_string()),
            filter_content: UNCHECK.to_string(),
        };
        vec![check_group, uncheck_group]
    }
}
