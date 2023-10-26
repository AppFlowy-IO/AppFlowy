use collab_database::fields::Field;
use collab_database::rows::{new_cell_builder, Cell, Cells, Row, RowDetail};
use serde::{Deserialize, Serialize};

use flowy_error::FlowyResult;

use crate::entities::{FieldType, GroupRowsNotificationPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{MultiSelectTypeOption, SelectOptionCellDataParser, TypeOption};
use crate::services::group::action::GroupCustomize;
use crate::services::group::controller::{BaseGroupController, GroupController};
use crate::services::group::{
  add_or_remove_select_option_row, generate_select_option_groups, make_no_status_group,
  move_group_row, remove_select_option_row, GeneratedGroups, GroupChangeset, GroupContext,
  GroupOperationInterceptor, GroupsBuilder, MoveGroupRowContext,
};

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
  MultiSelectGroupOperationInterceptorImpl,
>;

impl GroupCustomize for MultiSelectGroupController {
  type GroupTypeOption = MultiSelectTypeOption;

  fn can_group(
    &self,
    content: &str,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> bool {
    cell_data.iter().any(|option_id| option_id == content)
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
    row_detail: &RowDetail,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      if let Some(changeset) = add_or_remove_select_option_row(group, cell_data, row_detail) {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn delete_row(
    &mut self,
    row: &Row,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> Vec<GroupRowsNotificationPB> {
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
    _cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
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

  fn did_update_group(&self, _changeset: &GroupChangeset) -> FlowyResult<()> {
    todo!()
  }
}

impl GroupController for MultiSelectGroupController {
  fn did_update_field_type_option(&mut self, _field: &Field) {}

  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str) {
    match self.context.get_group(group_id) {
      None => tracing::warn!("Can not find the group: {}", group_id),
      Some((_, group)) => {
        let cell = insert_select_option_cell(vec![group.id.clone()], field);
        cells.insert(field.id.clone(), cell);
      },
    }
  }

  fn did_create_row(&mut self, row_detail: &RowDetail, group_id: &str) {
    if let Some(group) = self.context.get_mut_group(group_id) {
      group.add_row(row_detail.clone())
    }
  }
}

pub struct MultiSelectGroupGenerator;
impl GroupsBuilder for MultiSelectGroupGenerator {
  type Context = MultiSelectOptionGroupContext;
  type GroupTypeOption = MultiSelectTypeOption;

  fn build(
    field: &Field,
    _context: &Self::Context,
    type_option: &Self::GroupTypeOption,
  ) -> GeneratedGroups {
    let group_configs = generate_select_option_groups(&field.id, &type_option.options);
    GeneratedGroups {
      no_status_group: Some(make_no_status_group(field)),
      group_configs,
    }
  }
}

pub struct MultiSelectGroupOperationInterceptorImpl {}

impl GroupOperationInterceptor for MultiSelectGroupOperationInterceptorImpl {
  type GroupTypeOption = MultiSelectTypeOption;

  fn did_apply_group_changeset(
    &self,
    _changeset: &GroupChangeset,
    _type_option: &Self::GroupTypeOption,
  ) {
    todo!()
  }
}
