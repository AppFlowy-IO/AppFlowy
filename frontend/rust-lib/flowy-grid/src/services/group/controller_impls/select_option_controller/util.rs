use crate::entities::{GroupRowsChangesetPB, InsertedRowPB, RowPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::SelectOptionCellDataPB;
use crate::services::group::configuration::GenericGroupConfiguration;
use crate::services::group::Group;

use crate::services::group::controller::MoveGroupRowContext;
use flowy_grid_data_model::revision::{RowRevision, SelectOptionGroupConfigurationRevision};

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

pub fn move_select_option_row(
    group: &mut Group,
    group_changeset: &mut Vec<GroupRowsChangesetPB>,
    _cell_data: &SelectOptionCellDataPB,
    context: &mut MoveGroupRowContext,
) {
    let MoveGroupRowContext {
        row_rev,
        row_changeset,
        field_rev,
        to_group_id,
        to_row_id,
    } = context;

    let from_index = group.index_of_row(&row_rev.id);
    let to_index = match to_row_id {
        None => None,
        Some(to_row_id) => group.index_of_row(to_row_id),
    };

    // Remove the row in which group contains it
    if from_index.is_some() {
        group_changeset.push(GroupRowsChangesetPB::delete(group.id.clone(), vec![row_rev.id.clone()]));
        tracing::debug!("Group:{} remove row:{}", group.id, row_rev.id);
        group.remove_row(&row_rev.id);
    }

    if group.id == *to_group_id {
        let row_pb = RowPB::from(*row_rev);
        let mut inserted_row = InsertedRowPB::new(row_pb.clone());
        match to_index {
            None => {
                group_changeset.push(GroupRowsChangesetPB::insert(group.id.clone(), vec![inserted_row]));
                tracing::debug!("Group:{} append row:{}", group.id, row_rev.id);
                group.add_row(row_pb);
            }
            Some(to_index) => {
                if to_index < group.number_of_row() {
                    tracing::debug!("Group:{} insert row:{} at {} ", group.id, row_rev.id, to_index);
                    inserted_row.index = Some(to_index as i32);
                    group.insert_row(to_index, row_pb);
                } else {
                    tracing::debug!("Group:{} append row:{}", group.id, row_rev.id);
                    group.add_row(row_pb);
                }
                group_changeset.push(GroupRowsChangesetPB::insert(group.id.clone(), vec![inserted_row]));
            }
        }

        // Update the corresponding row's cell content.
        if from_index.is_none() {
            tracing::debug!("Mark row:{} belong to group:{}", row_rev.id, group.id);
            let cell_rev = insert_select_option_cell(group.id.clone(), field_rev);
            row_changeset.cell_by_field_id.insert(field_rev.id.clone(), cell_rev);
        }
    }
}
