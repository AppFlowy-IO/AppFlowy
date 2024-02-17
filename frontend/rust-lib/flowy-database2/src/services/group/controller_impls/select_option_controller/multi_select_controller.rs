use async_trait::async_trait;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{new_cell_builder, Cell, Cells, Row, RowDetail};
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};

use crate::entities::{FieldType, GroupPB, GroupRowsNotificationPB, InsertedGroupPB};
use crate::services::cell::insert_select_option_cell;
use crate::services::field::{
  MultiSelectTypeOption, SelectOption, SelectOptionCellDataParser, SelectTypeOptionSharedAction,
  TypeOption,
};
use crate::services::group::action::GroupCustomize;
use crate::services::group::controller::{BaseGroupController, GroupController};
use crate::services::group::{
  add_or_remove_select_option_row, generate_select_option_groups, make_no_status_group,
  move_group_row, remove_select_option_row, GeneratedGroups, Group, GroupChangeset, GroupContext,
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
  MultiSelectGroupBuilder,
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
  ) -> (Option<GroupPB>, Vec<GroupRowsNotificationPB>) {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      if let Some(changeset) = remove_select_option_row(group, cell_data, row) {
        changesets.push(changeset);
      }
    });
    (None, changesets)
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

  fn generate_new_group(
    &mut self,
    name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)> {
    let mut new_type_option = self.type_option.clone();
    let new_select_option = self.type_option.create_option(&name);
    new_type_option.insert_option(new_select_option.clone());

    let new_group = Group::new(new_select_option.id, new_select_option.name);
    let inserted_group_pb = self.context.add_new_group(new_group)?;

    Ok((Some(new_type_option.into()), Some(inserted_group_pb)))
  }

  fn delete_group_custom(&mut self, group_id: &str) -> FlowyResult<Option<TypeOptionData>> {
    if let Some(option_index) = self
      .type_option
      .options
      .iter()
      .position(|option| option.id == group_id)
    {
      // Remove the option if the group is found
      let mut new_type_option = self.type_option.clone();
      new_type_option.options.remove(option_index);
      Ok(Some(new_type_option.into()))
    } else {
      Ok(None)
    }
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
}

pub struct MultiSelectGroupBuilder;
#[async_trait]
impl GroupsBuilder for MultiSelectGroupBuilder {
  type Context = MultiSelectOptionGroupContext;
  type GroupTypeOption = MultiSelectTypeOption;

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

pub struct MultiSelectGroupOperationInterceptorImpl;

#[async_trait]
impl GroupOperationInterceptor for MultiSelectGroupOperationInterceptorImpl {
  type GroupTypeOption = MultiSelectTypeOption;

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
