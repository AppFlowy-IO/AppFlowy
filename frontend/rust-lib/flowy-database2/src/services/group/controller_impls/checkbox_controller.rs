use async_trait::async_trait;
use collab_database::fields::checkbox_type_option::CheckboxTypeOption;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{new_cell_builder, Cell, Cells, Row};
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};

use crate::entities::{FieldType, GroupPB, GroupRowsNotificationPB, InsertedRowPB, RowMetaPB};
use crate::services::cell::insert_checkbox_cell;
use crate::services::field::{CheckboxCellDataParser, TypeOption, CHECK, UNCHECK};
use crate::services::group::action::GroupCustomize;
use crate::services::group::configuration::GroupControllerContext;
use crate::services::group::controller::BaseGroupController;
use crate::services::group::{
  move_group_row, GeneratedGroups, Group, GroupsBuilder, MoveGroupRowContext,
};

#[derive(Default, Serialize, Deserialize)]
pub struct CheckboxGroupConfiguration {
  pub hide_empty: bool,
}

pub type CheckboxGroupController =
  BaseGroupController<CheckboxGroupConfiguration, CheckboxGroupBuilder, CheckboxCellDataParser>;

pub type CheckboxGroupControllerContext = GroupControllerContext<CheckboxGroupConfiguration>;

#[async_trait]
impl GroupCustomize for CheckboxGroupController {
  type GroupTypeOption = CheckboxTypeOption;
  fn placeholder_cell(&self) -> Option<Cell> {
    let mut cell = new_cell_builder(FieldType::Checkbox);
    cell.insert("data".into(), UNCHECK.into());
    Some(cell)
  }

  fn can_group(
    &self,
    content: &str,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> bool {
    if cell_data.is_checked {
      content == CHECK
    } else {
      content == UNCHECK
    }
  }

  fn add_or_remove_row_when_cell_changed(
    &mut self,
    row: &Row,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
      let is_not_contained = !group.contains_row(&row.id);
      if group.id == CHECK {
        if !cell_data.is_checked {
          // Remove the row if the group.id is CHECK but the cell_data is UNCHECK
          changeset.deleted_rows.push(row.id.clone().into_inner());
          group.remove_row(&row.id);
        } else {
          // Add the row to the group if the group didn't contain the row
          if is_not_contained {
            changeset
              .inserted_rows
              .push(InsertedRowPB::new(RowMetaPB::from(row)));
            group.add_row(row.clone());
          }
        }
      }

      if group.id == UNCHECK {
        if cell_data.is_checked {
          // Remove the row if the group.id is UNCHECK but the cell_data is CHECK
          changeset.deleted_rows.push(row.id.clone().into_inner());
          group.remove_row(&row.id);
        } else {
          // Add the row to the group if the group didn't contain the row
          if is_not_contained {
            changeset
              .inserted_rows
              .push(InsertedRowPB::new(RowMetaPB::from(row)));
            group.add_row(row.clone());
          }
        }
      }

      if !changeset.is_empty() {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn delete_row(
    &mut self,
    row: &Row,
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> (Option<GroupPB>, Vec<GroupRowsNotificationPB>) {
    let mut changesets = vec![];
    self.context.iter_mut_groups(|group| {
      let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
      if group.contains_row(&row.id) {
        changeset.deleted_rows.push(row.id.clone().into_inner());
        group.remove_row(&row.id);
      }

      if !changeset.is_empty() {
        changesets.push(changeset);
      }
    });
    (None, changesets)
  }

  fn move_row(&mut self, mut context: MoveGroupRowContext) -> Vec<GroupRowsNotificationPB> {
    let mut group_changeset = vec![];
    self.context.iter_mut_groups(|group| {
      if let Some(changeset) = move_group_row(group, &mut context) {
        group_changeset.push(changeset);
      }
    });
    group_changeset
  }

  async fn delete_group(&mut self, _group_id: &str) -> FlowyResult<Option<TypeOptionData>> {
    Ok(None)
  }

  fn will_create_row(&self, cells: &mut Cells, field: &Field, group_id: &str) {
    match self.context.get_group(group_id) {
      None => tracing::warn!("Can not find the group: {}", group_id),
      Some((_, group)) => {
        let is_checked = group.id == CHECK;
        let cell = insert_checkbox_cell(is_checked, field);
        cells.insert(field.id.clone(), cell);
      },
    }
  }
}

pub struct CheckboxGroupBuilder();
#[async_trait]
impl GroupsBuilder for CheckboxGroupBuilder {
  type Context = CheckboxGroupControllerContext;
  type GroupTypeOption = CheckboxTypeOption;

  async fn build(
    _field: &Field,
    _context: &Self::Context,
    _type_option: &Self::GroupTypeOption,
  ) -> GeneratedGroups {
    let check_group = Group::new(CHECK.to_string());
    let uncheck_group = Group::new(UNCHECK.to_string());

    GeneratedGroups {
      no_status_group: None,
      groups: vec![check_group, uncheck_group],
    }
  }
}
