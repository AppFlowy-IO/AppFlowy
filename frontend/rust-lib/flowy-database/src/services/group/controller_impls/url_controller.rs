use crate::entities::{GroupPB, GroupRowsNotificationPB, InsertedGroupPB, InsertedRowPB, RowPB};
use crate::services::cell::insert_url_cell;
use crate::services::field::{URLCellData, URLCellDataPB, URLCellDataParser, URLTypeOptionPB};
use crate::services::group::action::GroupCustomize;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
    GenericGroupController, GroupController, GroupGenerator, MoveGroupRowContext,
};
use crate::services::group::{make_no_status_group, move_group_row, GeneratedGroupConfig, GeneratedGroupContext};
use flowy_error::FlowyResult;
use grid_model::{CellRevision, FieldRevision, GroupRevision, RowRevision, URLGroupConfigurationRevision};

pub type URLGroupController =
    GenericGroupController<URLGroupConfigurationRevision, URLTypeOptionPB, URLGroupGenerator, URLCellDataParser>;

pub type URLGroupContext = GroupContext<URLGroupConfigurationRevision>;

impl GroupCustomize for URLGroupController {
    type CellData = URLCellDataPB;

    fn placeholder_cell(&self) -> Option<CellRevision> {
        Some(CellRevision::new("".to_string()))
    }

    fn can_group(&self, content: &str, cell_data: &Self::CellData) -> bool {
        cell_data.content == content
    }

    fn create_or_delete_group_when_cell_changed(
        &mut self,
        row_rev: &RowRevision,
        old_cell_data: Option<&Self::CellData>,
        cell_data: &Self::CellData,
    ) -> FlowyResult<(Option<InsertedGroupPB>, Option<GroupPB>)> {
        // Just return if the group with this url already exists
        let mut inserted_group = None;
        if self.group_ctx.get_group(&cell_data.url).is_none() {
            let cell_data: URLCellData = cell_data.clone().into();
            let group_revision = make_group_from_url_cell(&cell_data);
            let mut new_group = self.group_ctx.add_new_group(group_revision)?;
            new_group.group.rows.push(RowPB::from(row_rev));
            inserted_group = Some(new_group);
        }

        // Delete the old url group if there are no rows in that group
        let deleted_group =
            match old_cell_data.and_then(|old_cell_data| self.group_ctx.get_group(&old_cell_data.content)) {
                None => None,
                Some((_, group)) => {
                    if group.rows.len() == 1 {
                        Some(group.clone())
                    } else {
                        None
                    }
                }
            };

        let deleted_group = match deleted_group {
            None => None,
            Some(group) => {
                self.group_ctx.delete_group(&group.id)?;
                Some(GroupPB::from(group.clone()))
            }
        };

        Ok((inserted_group, deleted_group))
    }

    fn add_or_remove_row_when_cell_changed(
        &mut self,
        row_rev: &RowRevision,
        cell_data: &Self::CellData,
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

    fn delete_row(&mut self, row_rev: &RowRevision, _cell_data: &Self::CellData) -> Vec<GroupRowsNotificationPB> {
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
        _cell_data: &Self::CellData,
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

    fn delete_group_when_move_row(&mut self, _row_rev: &RowRevision, cell_data: &Self::CellData) -> Option<GroupPB> {
        let mut deleted_group = None;
        if let Some((_, group)) = self.group_ctx.get_group(&cell_data.content) {
            if group.rows.len() == 1 {
                deleted_group = Some(GroupPB::from(group.clone()));
            }
        }
        if deleted_group.is_some() {
            let _ = self.group_ctx.delete_group(&deleted_group.as_ref().unwrap().group_id);
        }
        deleted_group
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
            .map(|cell| GeneratedGroupConfig {
                group_rev: make_group_from_url_cell(&cell),
                filter_content: cell.content,
            })
            .collect();

        let no_status_group = Some(make_no_status_group(field_rev));
        GeneratedGroupContext {
            no_status_group,
            group_configs,
        }
    }
}

fn make_group_from_url_cell(cell: &URLCellData) -> GroupRevision {
    let group_id = cell.content.clone();
    let group_name = cell.content.clone();
    GroupRevision::new(group_id, group_name)
}
