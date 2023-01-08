use crate::entities::{GroupRowsNotificationPB, InsertedRowPB, RowPB};
use crate::services::cell::insert_url_cell;
use crate::services::field::{URLCellDataPB, URLCellDataParser, URLTypeOptionPB};
use crate::services::group::action::GroupControllerCustomActions;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};

use crate::services::group::{make_no_status_group, move_group_row, GeneratedGroupContext};
use grid_rev_model::{FieldRevision, RowRevision, URLGroupConfigurationRevision};

pub type URLGroupController =
    GenericGroupController<URLGroupConfigurationRevision, URLTypeOptionPB, URLGroupGenerator, URLCellDataParser>;

pub type URLGroupContext = GroupContext<URLGroupConfigurationRevision>;

impl GroupControllerCustomActions for URLGroupController {
    type CellDataType = URLCellDataPB;

    fn can_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool {
        cell_data.content == content
    }

    fn add_or_remove_row_in_groups_if_match(
        &mut self,
        row_rev: &RowRevision,
        cell_data: &Self::CellDataType,
    ) -> Vec<GroupRowsNotificationPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_status_groups(|group| {
            let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
            let is_not_contained = !group.contains_row(&row_rev.id);
            if group.id == cell_data.content {
                // Add the row to the group if the group didn't contain the row
                if is_not_contained {
                    let row_pb = RowPB::from(row_rev);
                    changeset.inserted_rows.push(InsertedRowPB::new(row_pb.clone()));
                    group.add_row(row_pb);
                }
            }

            // Remove the row if the group.id is CHECK but the cell_data is UNCHECK
            changeset.deleted_rows.push(row_rev.id.clone());
            group.remove_row(&row_rev.id);

            if !changeset.is_empty() {
                changesets.push(changeset);
            }
        });
        changesets
    }

    fn delete_row(&mut self, row_rev: &RowRevision, _cell_data: &Self::CellDataType) -> Vec<GroupRowsNotificationPB> {
        let mut changesets = vec![];
        self.group_ctx.iter_mut_groups(|group| {
            let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
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

    fn move_row(
        &mut self,
        _cell_data: &Self::CellDataType,
        mut context: MoveGroupRowContext,
    ) -> Vec<GroupRowsNotificationPB> {
        let mut group_changeset = vec![];
        self.group_ctx.iter_mut_groups(|group| {
            if let Some(changeset) = move_group_row(group, &mut context) {
                group_changeset.push(changeset);
            }
        });
        group_changeset
    }
}

impl GroupController for URLGroupController {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str) {
        match self.group_ctx.get_group(group_id) {
            None => tracing::warn!("Can not find the group: {}", group_id),
            Some((_, group)) => {
                let cell_rev = insert_url_cell(group.id.clone(), field_rev);
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

pub struct URLGroupGenerator();
impl GroupGenerator for URLGroupGenerator {
    type Context = URLGroupContext;
    type TypeOptionType = URLTypeOptionPB;

    fn generate_groups(
        field_rev: &FieldRevision,
        group_ctx: &Self::Context,
        type_option: &Option<Self::TypeOptionType>,
    ) -> GeneratedGroupContext {
        let group_configs = match type_option {
            None => vec![],
            Some(type_option) => {
                tracing::info!("Logging {}, {}", type_option.data, type_option.url);
                vec![]
            }
        };

        GeneratedGroupContext {
            no_status_group: Some(make_no_status_group(field_rev)),
            group_configs,
        }
    }
}
