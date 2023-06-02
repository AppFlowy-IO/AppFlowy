use crate::entities::{FieldType, GroupRowsNotificationPB, SelectOptionCellDataPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{MultiSelectTypeOption, SelectOptionCellDataParser};
use crate::services::group::action::GroupCustomize;
use crate::services::group::controller::{
  BaseGroupController, GroupController, GroupsBuilder, MoveGroupRowContext,
};
use crate::services::group::{
  add_or_remove_select_option_row, generate_select_option_groups, make_no_status_group,
  move_group_row, remove_select_option_row, GeneratedGroups, GroupContext,
};
use collab_database::fields::Field;
use collab_database::rows::{new_cell_builder, Cell, Cells, Row};
use std::sync::Arc;

use serde::{Deserialize, Serialize};

#[derive(Default, Serialize, Deserialize)]
pub struct MultiSelectGroupConfiguration {
  pub hide_empty: bool,
}

pub type MultiSelectOptionGroupContext = GroupContext<MultiSelectGroupConfiguration>;
// MultiSelect
pub type MultiSelectGroupController = BaseGroupController<
  MultiSelectGroupConfiguration,
  MultiSelectTypeOption,
  MultiSelectGroupGenerator,
  SelectOptionCellDataParser,
>;

impl GroupCustomize for MultiSelectGroupController {
  type CellData = SelectOptionCellDataPB;

  fn can_group(&self, content: &str, cell_data: &Self::CellData) -> bool {
    cell_data
      .select_options
      .iter()
      .any(|option| option.id == content)
  }

  fn placeholder_cell(&self) -> Option<Cell> {
    Some(
      new_cell_builder(FieldType::MultiSelect)
        .insert_str_value("data", "")
        .build(),
    )
  }

  fn add_or_remove_row_when_cell_changed(
    &mut self,
    row: &Row,
    cell_data: &Self::CellData,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      if let Some(changeset) = add_or_remove_select_option_row(group, cell_data, row) {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn delete_row(&mut self, row: &Row, cell_data: &Self::CellData) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      if let Some(changeset) = remove_select_option_row(group, cell_data, row) {
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
    self.context.iter_mut_groups(|group| {
      if let Some(changeset) = move_group_row(group, &mut context) {
        group_changeset.push(changeset);
      }
    });
    group_changeset
  }
}

impl GroupController for MultiSelectGroupController {
  fn did_update_field_type_option(&mut self, _field: &Arc<Field>) {}

  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str) {
    match self.context.get_group(group_id) {
      None => tracing::warn!("Can not find the group: {}", group_id),
      Some((_, group)) => {
        let cell = insert_select_option_cell(vec![group.id.clone()], field);
        cells.insert(field.id.clone(), cell);
      },
    }
  }

  fn did_create_row(&mut self, row: &Row, group_id: &str) {
    if let Some(group) = self.context.get_mut_group(group_id) {
      group.add_row(row.clone())
    }
  }
}

pub struct MultiSelectGroupGenerator;
impl GroupsBuilder for MultiSelectGroupGenerator {
  type Context = MultiSelectOptionGroupContext;
  type TypeOptionType = MultiSelectTypeOption;

  fn build(
    field: &Field,
    _context: &Self::Context,
    type_option: &Option<Self::TypeOptionType>,
  ) -> GeneratedGroups {
    let group_configs = match type_option {
      None => vec![],
      Some(type_option) => generate_select_option_groups(&field.id, &type_option.options),
    };

    GeneratedGroups {
      no_status_group: Some(make_no_status_group(field)),
      group_configs,
    }
  }
}
