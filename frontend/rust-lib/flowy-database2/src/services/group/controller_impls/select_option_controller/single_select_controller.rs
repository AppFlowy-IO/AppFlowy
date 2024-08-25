use async_trait::async_trait;
use collab_database::entity::SelectOption;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{new_cell_builder, Cell, Cells, Row};
use flowy_error::{FlowyError, FlowyResult};
use serde::{Deserialize, Serialize};

use crate::entities::{FieldType, GroupPB, GroupRowsNotificationPB, InsertedGroupPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{
  SelectOptionCellDataParser, SelectTypeOptionSharedAction, SingleSelectTypeOption, TypeOption,
};
use crate::services::group::action::GroupCustomize;
use crate::services::group::controller::BaseGroupController;
use crate::services::group::controller_impls::select_option_controller::util::*;
use crate::services::group::{
  make_no_status_group, GeneratedGroups, Group, GroupChangeset, GroupControllerContext,
  GroupsBuilder, MoveGroupRowContext,
};

#[derive(Default, Serialize, Deserialize)]
pub struct SingleSelectGroupConfiguration {
  pub hide_empty: bool,
}

pub type SingleSelectGroupControllerContext =
  GroupControllerContext<SingleSelectGroupConfiguration>;

// SingleSelect
pub type SingleSelectGroupController = BaseGroupController<
  SingleSelectGroupConfiguration,
  SingleSelectGroupBuilder,
  SelectOptionCellDataParser,
>;

#[async_trait]
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
    let mut cell = new_cell_builder(FieldType::SingleSelect);
    cell.insert("data".into(), "".into());
    Some(cell)
  }

  fn add_or_remove_row_when_cell_changed(
    &mut self,
    row: &Row,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellProtobufType,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      if let Some(changeset) = add_or_remove_select_option_row(group, cell_data, row) {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn delete_row(
    &mut self,
    row: &Row,
    cell_data: &<Self::GroupTypeOption as TypeOption>::CellData,
  ) -> (Option<GroupPB>, Vec<GroupRowsNotificationPB>) {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      if let Some(changeset) = remove_select_option_row(group, cell_data, row) {
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

  async fn create_group(
    &mut self,
    name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)> {
    let mut new_type_option = self.get_grouping_field_type_option().await.ok_or_else(|| {
      FlowyError::internal().with_context("Failed to get grouping field type option")
    })?;
    let new_select_option = new_type_option.create_option(&name);
    new_type_option.insert_option(new_select_option.clone());

    let new_group = Group::new(new_select_option.id);
    let inserted_group_pb = self.context.add_new_group(new_group)?;

    Ok((Some(new_type_option.into()), Some(inserted_group_pb)))
  }

  async fn delete_group(&mut self, group_id: &str) -> FlowyResult<Option<TypeOptionData>> {
    let mut new_type_option = self.get_grouping_field_type_option().await.ok_or_else(|| {
      FlowyError::internal().with_context("Failed to get grouping field type option")
    })?;
    if let Some(option_index) = new_type_option
      .options
      .iter()
      .position(|option| option.id == group_id)
    {
      // Remove the option if the group is found
      new_type_option.options.remove(option_index);
      Ok(Some(new_type_option.into()))
    } else {
      Ok(None)
    }
  }

  fn update_type_option_when_update_group(
    &mut self,
    changeset: &GroupChangeset,
    type_option: &Self::GroupTypeOption,
  ) -> Option<Self::GroupTypeOption> {
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

      Some(new_type_option)
    } else {
      None
    }
  }

  fn will_create_row(&self, cells: &mut Cells, field: &Field, group_id: &str) {
    match self.context.get_group(group_id) {
      None => tracing::warn!("Can not find the group: {}", group_id),
      Some((_index, group)) => {
        let cell = insert_select_option_cell(vec![group.id.clone()], field);
        cells.insert(field.id.clone(), cell);
      },
    }
  }
}

pub struct SingleSelectGroupBuilder();
#[async_trait]
impl GroupsBuilder for SingleSelectGroupBuilder {
  type Context = SingleSelectGroupControllerContext;
  type GroupTypeOption = SingleSelectTypeOption;
  async fn build(
    field: &Field,
    _context: &Self::Context,
    type_option: &Self::GroupTypeOption,
  ) -> GeneratedGroups {
    let groups = generate_select_option_groups(&field.id, &type_option.options);

    GeneratedGroups {
      no_status_group: Some(make_no_status_group(field)),
      groups,
    }
  }
}
