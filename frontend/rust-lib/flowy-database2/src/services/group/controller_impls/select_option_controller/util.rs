use crate::entities::{
  FieldType, GroupRowsNotificationPB, InsertedRowPB, RowMetaPB, SelectOptionCellDataPB,
};
use crate::services::cell::{
  insert_checkbox_cell, insert_date_cell, insert_select_option_cell, insert_url_cell,
};
use crate::services::field::CHECK;
use crate::services::group::{Group, GroupData, MoveGroupRowContext};
use chrono::NaiveDateTime;
use collab_database::fields::select_type_option::{SelectOption, SelectOptionIds};
use collab_database::fields::Field;
use collab_database::rows::{Cell, Row};
use tracing::debug;

pub fn add_or_remove_select_option_row(
  group: &mut GroupData,
  cell_data: &SelectOptionCellDataPB,
  row: &Row,
) -> Option<GroupRowsNotificationPB> {
  let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
  if cell_data.select_options.is_empty() {
    if group.contains_row(&row.id) {
      group.remove_row(&row.id);
      changeset.deleted_rows.push(row.id.clone().into_inner());
    }
  } else {
    cell_data.select_options.iter().for_each(|option| {
      if option.id == group.id {
        if !group.contains_row(&row.id) {
          changeset
            .inserted_rows
            .push(InsertedRowPB::new(RowMetaPB::from(row.clone())));
          group.add_row(row.clone());
        }
      } else if group.contains_row(&row.id) {
        group.remove_row(&row.id);
        changeset.deleted_rows.push(row.id.clone().into_inner());
      }
    });
  }

  if changeset.is_empty() {
    None
  } else {
    Some(changeset)
  }
}

pub fn remove_select_option_row(
  group: &mut GroupData,
  cell_data: &SelectOptionIds,
  row: &Row,
) -> Option<GroupRowsNotificationPB> {
  let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
  cell_data.iter().for_each(|option_id| {
    if option_id == &group.id && group.contains_row(&row.id) {
      group.remove_row(&row.id);
      changeset.deleted_rows.push(row.id.clone().into_inner());
    }
  });

  if changeset.is_empty() {
    None
  } else {
    Some(changeset)
  }
}

pub fn move_group_row(
  group: &mut GroupData,
  context: &mut MoveGroupRowContext,
) -> Option<GroupRowsNotificationPB> {
  let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
  let MoveGroupRowContext {
    row,
    updated_cells,
    field,
    to_group_id,
    to_row_id,
  } = context;

  let from_index = group.index_of_row(&row.id);
  let to_index = match to_row_id {
    None => None,
    Some(to_row_id) => group.index_of_row(to_row_id),
  };

  // Remove the row in which group contains it
  if from_index.is_some() {
    changeset.deleted_rows.push(row.id.clone().into_inner());
    group.remove_row(&row.id);
  }

  if group.id == *to_group_id {
    let mut inserted_row = InsertedRowPB::new(RowMetaPB::from((*row).clone()));
    match to_index {
      None => {
        changeset.inserted_rows.push(inserted_row);
        group.add_row(row.clone());
      },
      Some(to_index) => {
        if to_index < group.number_of_row() {
          inserted_row.index = Some(to_index as i32);
          group.insert_row(to_index, row.clone());
        } else {
          tracing::warn!(
            "[Database Group]: Move to index: {} is out of bounds",
            to_index
          );
          group.add_row(row.clone());
        }
        changeset.inserted_rows.push(inserted_row);
      },
    }

    // Update the corresponding row's cell content.
    // If the from_index is none which means the row is not belong to this group before and
    // it is moved from other groups.
    if from_index.is_none() {
      let cell = make_inserted_cell(&group.id, field);
      if let Some(cell) = cell {
        debug!(
          "[Database Group]: Update content of the cell in the row:{} to group:{}",
          row.id, group.id
        );
        updated_cells.insert(field.id.clone(), cell);
      }
    }
  }
  if changeset.is_empty() {
    None
  } else {
    Some(changeset)
  }
}

pub fn make_inserted_cell(group_id: &str, field: &Field) -> Option<Cell> {
  let field_type = FieldType::from(field.field_type);
  match field_type {
    FieldType::SingleSelect => {
      let cell = insert_select_option_cell(vec![group_id.to_owned()], field);
      Some(cell)
    },
    FieldType::MultiSelect => {
      let cell = insert_select_option_cell(vec![group_id.to_owned()], field);
      Some(cell)
    },
    FieldType::Checkbox => {
      let cell = insert_checkbox_cell(group_id == CHECK, field);
      Some(cell)
    },
    FieldType::URL => {
      let cell = insert_url_cell(group_id.to_owned(), field);
      Some(cell)
    },
    FieldType::DateTime => {
      let date =
        NaiveDateTime::parse_from_str(&format!("{} 00:00:00", group_id), "%Y/%m/%d %H:%M:%S")
          .unwrap();
      let cell = insert_date_cell(date.and_utc().timestamp(), None, None, Some(false), field);
      Some(cell)
    },
    _ => {
      tracing::warn!("Unknown field type: {:?}", field_type);
      None
    },
  }
}

pub fn generate_select_option_groups(_field_id: &str, options: &[SelectOption]) -> Vec<Group> {
  let groups = options
    .iter()
    .map(|option| Group::new(option.id.clone()))
    .collect();

  groups
}
