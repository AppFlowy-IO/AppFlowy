use crate::entities::{FieldType, GroupRowsNotificationPB, SelectOptionCellDataPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{SelectOptionCellDataParser, SingleSelectTypeOption};
use crate::services::group::action::GroupCustomize;
use collab_database::fields::Field;
use collab_database::rows::{new_cell_builder, Cell, Cells, Row};
use std::sync::Arc;

use crate::services::group::controller::{
  BaseGroupController, GroupController, GroupsBuilder, MoveGroupRowContext,
};
use crate::services::group::controller_impls::select_option_controller::util::*;
use crate::services::group::entities::GroupData;
use crate::services::group::{make_no_status_group, GeneratedGroups, GroupContext};

use serde::{Deserialize, Serialize};

#[derive(Default, Serialize, Deserialize)]
pub struct SingleSelectGroupConfiguration {
  pub hide_empty: bool,
}

pub type SingleSelectOptionGroupContext = GroupContext<SingleSelectGroupConfiguration>;

// SingleSelect
pub type SingleSelectGroupController = BaseGroupController<
  SingleSelectGroupConfiguration,
  SingleSelectTypeOption,
  SingleSelectGroupGenerator,
  SelectOptionCellDataParser,
>;

impl GroupCustomize for SingleSelectGroupController {
  type CellData = SelectOptionCellDataPB;
  fn can_group(&self, content: &str, cell_data: &Self::CellData) -> bool {
    cell_data
      .select_options
      .iter()
      .any(|option| option.id == content)
  }

  fn placeholder_cell(&self) -> Option<Cell> {
    Some(
      new_cell_builder(FieldType::SingleSelect)
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

impl GroupController for SingleSelectGroupController {
  fn did_update_field_type_option(&mut self, _field: &Arc<Field>) {}

  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str) {
    let group: Option<&mut GroupData> = self.context.get_mut_group(group_id);
    match group {
      None => {},
      Some(group) => {
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

pub struct SingleSelectGroupGenerator();
impl GroupsBuilder for SingleSelectGroupGenerator {
  type Context = SingleSelectOptionGroupContext;
  type TypeOptionType = SingleSelectTypeOption;
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
