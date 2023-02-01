use crate::entities::{GroupRowsNotificationPB, InsertedRowPB, RowPB};
use crate::services::cell::insert_url_cell;
use crate::services::field::{URLCellDataPB, URLCellDataParser, URLTypeOptionPB};
use crate::services::group::action::GroupControllerCustomActions;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};
use crate::services::group::{make_no_status_group, move_group_row, GeneratedGroupConfig, GeneratedGroupContext};
use grid_model::{CellRevision, FieldRevision, GroupRevision, RowRevision, URLGroupConfigurationRevision};

pub type URLGroupController =
    GenericGroupController<URLGroupConfigurationRevision, URLTypeOptionPB, URLGroupGenerator, URLCellDataParser>;

pub type URLGroupContext = GroupContext<URLGroupConfigurationRevision>;

impl GroupControllerCustomActions for URLGroupController {
    type CellDataType = URLCellDataPB;

    fn default_cell_rev(&self) -> Option<CellRevision> {
        Some(CellRevision::new("".to_string()))
    }

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
            if group.id == cell_data.content {
                if !group.contains_row(&row_rev.id) {
                    let row_pb = RowPB::from(row_rev);
                    changeset.inserted_rows.push(InsertedRowPB::new(row_pb.clone()));
                    group.add_row(row_pb);
                }
            } else if group.contains_row(&row_rev.id) {
                changeset.deleted_rows.push(row_rev.id.clone());
                group.remove_row(&row_rev.id);
            }

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
        _type_option: &Option<Self::TypeOptionType>,
    ) -> GeneratedGroupContext {
        // Read all the cells for the grouping field
        let cells = futures::executor::block_on(group_ctx.get_all_cells());

        // Generate the groups
        let group_configs = cells
            .into_iter()
            .flat_map(|value| value.into_url_field_cell_data())
            .map(|cell| {
                let group_id = cell.content.clone();
                let group_name = cell.content.clone();
                GeneratedGroupConfig {
                    group_rev: GroupRevision::new(group_id, group_name),
                    filter_content: cell.content,
                }
            })
            .collect();

        let no_status_group = Some(make_no_status_group(field_rev));
        GeneratedGroupContext {
            no_status_group,
            group_configs,
        }
    }
}
