use crate::entities::{GroupRowsChangesetPB, InsertedRowPB, RowPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::SelectOptionCellDataPB;
use crate::services::group::configuration::GenericGroupConfiguration;
use crate::services::group::Group;

use flowy_grid_data_model::revision::{
    FieldRevision, RowChangeset, RowRevision, SelectOptionGroupConfigurationRevision,
};

pub type SelectOptionGroupConfiguration = GenericGroupConfiguration<SelectOptionGroupConfigurationRevision>;

pub fn add_row(
    group: &mut Group,
    changesets: &mut Vec<GroupRowsChangesetPB>,
    cell_data: &SelectOptionCellDataPB,
    row_rev: &RowRevision,
) {
    cell_data.select_options.iter().for_each(|option| {
        if option.id == group.id {
            if !group.contains_row(&row_rev.id) {
                let row_pb = RowPB::from(row_rev);
                changesets.push(GroupRowsChangesetPB::insert(
                    group.id.clone(),
                    vec![InsertedRowPB::new(row_pb.clone())],
                ));
                group.add_row(row_pb);
            }
        } else if group.contains_row(&row_rev.id) {
            changesets.push(GroupRowsChangesetPB::delete(group.id.clone(), vec![row_rev.id.clone()]));
            group.remove_row(&row_rev.id);
        }
    });
}

pub fn remove_row(
    group: &mut Group,
    changesets: &mut Vec<GroupRowsChangesetPB>,
    cell_data: &SelectOptionCellDataPB,
    row_rev: &RowRevision,
) {
    cell_data.select_options.iter().for_each(|option| {
        if option.id == group.id && group.contains_row(&row_rev.id) {
            changesets.push(GroupRowsChangesetPB::delete(group.id.clone(), vec![row_rev.id.clone()]));
            group.remove_row(&row_rev.id);
        }
    });
}

pub fn move_row(
    group: &mut Group,
    group_changeset: &mut Vec<GroupRowsChangesetPB>,
    field_rev: &FieldRevision,
    row_rev: &RowRevision,
    row_changeset: &mut RowChangeset,
    cell_data: &SelectOptionCellDataPB,
    to_row_id: &str,
) {
    cell_data.select_options.iter().for_each(|option| {
        // Remove the row in which group contains the row
        let is_group_contains = group.contains_row(&row_rev.id);
        let to_index = group.index_of_row(to_row_id);

        if option.id == group.id && is_group_contains {
            group_changeset.push(GroupRowsChangesetPB::delete(group.id.clone(), vec![row_rev.id.clone()]));
            group.remove_row(&row_rev.id);
        }

        // Find the inserted group
        if let Some(to_index) = to_index {
            let row_pb = RowPB::from(row_rev);
            let inserted_row = InsertedRowPB {
                row: row_pb.clone(),
                index: Some(to_index as i32),
            };
            group_changeset.push(GroupRowsChangesetPB::insert(group.id.clone(), vec![inserted_row]));
            if group.number_of_row() == to_index {
                group.add_row(row_pb);
            } else {
                group.insert_row(to_index, row_pb);
            }
        }

        // If the inserted row comes from other group, it needs to update the corresponding cell content.
        if to_index.is_some() && option.id != group.id {
            // Update the corresponding row's cell content.
            let cell_rev = insert_select_option_cell(group.id.clone(), field_rev);
            row_changeset.cell_by_field_id.insert(field_rev.id.clone(), cell_rev);
        }
    });
}
