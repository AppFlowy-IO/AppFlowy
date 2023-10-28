use async_trait::async_trait;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{new_cell_builder, Cell, Cells, Row, RowDetail};
use serde::{Deserialize, Serialize};

use crate::entities::{FieldType, GroupRowsNotificationPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{
  SelectOption, SelectOptionCellDataParser, SelectTypeOptionSharedAction, SingleSelectTypeOption,
  TypeOption,
};
use crate::services::group::action::GroupCustomize;
use crate::services::group::controller::{BaseGroupController, GroupController};
use crate::services::group::controller_impls::select_option_controller::util::*;
use crate::services::group::entities::GroupData;
use crate::services::group::{
  make_no_status_group, GeneratedGroups, GroupChangeset, GroupContext, GroupOperationInterceptor,
  GroupsBuilder, MoveGroupRowContext,
};

#[derive(Default, Serialize, Deserialize)]
pub struct SingleSelectGroupConfiguration {
  pub hide_empty: bool,
}

pub type SingleSelectOptionGroupContext = GroupContext<SingleSelectGroupConfiguration>;

// SingleSelect
pub type SingleSelectGroupController = BaseGroupController<
  SingleSelectGroupConfiguration,
  SingleSelectTypeOption,
  SingleSelectGroupBuilder,
  SelectOptionCellDataParser,
  SingleSelectGroupOperationInterceptorImpl,
>;

impl GroupCustomize for SingleSelectGroupController {
  type GroupTypeOption = SingleSelectTypeOption;
  fn can_group(
    &self,
    content: &str,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> bool {
    cell_data.iter().any(|option_id| option_id == content)
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
}

impl GroupController for SingleSelectGroupController {
  fn did_update_field_type_option(&mut self, _field: &Field) {}

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

  fn did_create_row(&mut self, row_detail: &RowDetail, group_id: &str) {
    if let Some(group) = self.context.get_mut_group(group_id) {
      group.add_row(row_detail.clone())
    }
  }
}

pub struct SingleSelectGroupBuilder();
#[async_trait]
impl GroupsBuilder for SingleSelectGroupBuilder {
  type Context = SingleSelectOptionGroupContext;
  type GroupTypeOption = SingleSelectTypeOption;
  async fn build(
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

pub struct SingleSelectGroupOperationInterceptorImpl;

#[async_trait]
impl GroupOperationInterceptor for SingleSelectGroupOperationInterceptorImpl {
  type GroupTypeOption = SingleSelectTypeOption;

  #[tracing::instrument(level = "trace", skip_all)]
  async fn type_option_from_group_changeset(
    &self,
    changeset: &GroupChangeset,
    type_option: &Self::GroupTypeOption,
    _view_id: &str,
  ) -> Option<TypeOptionData> {
    if let Some(name) = &changeset.name {
      let mut new_type_option = type_option.clone();
      let select_option = type_option
        .options
        .iter()
        .find(|option| option.id == changeset.group_id)
        .unwrap();

      let new_select_option = SelectOption {
        name: name.to_owned(),
        ..select_option.to_owned()
      };
      new_type_option.insert_option(new_select_option);
      return Some(new_type_option.into());
    }

    None
  }
}
