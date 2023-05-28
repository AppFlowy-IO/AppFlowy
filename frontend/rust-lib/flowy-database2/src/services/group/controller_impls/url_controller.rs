use collab_database::fields::Field;
use collab_database::rows::{new_cell_builder, Cell, Cells, Row};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

use flowy_error::FlowyResult;

use crate::entities::{
  FieldType, GroupPB, GroupRowsNotificationPB, InsertedGroupPB, InsertedRowPB, RowPB, URLCellDataPB,
};
use crate::services::cell::insert_url_cell;
use crate::services::field::{URLCellData, URLCellDataParser, URLTypeOption};
use crate::services::group::action::GroupCustomize;
use crate::services::group::configuration::GroupContext;
use crate::services::group::controller::{
  BaseGroupController, GroupController, GroupsBuilder, MoveGroupRowContext,
};
use crate::services::group::{
  make_no_status_group, move_group_row, GeneratedGroupConfig, GeneratedGroups, Group,
};

#[derive(Default, Serialize, Deserialize)]
pub struct URLGroupConfiguration {
  pub hide_empty: bool,
}

pub type URLGroupController =
  BaseGroupController<URLGroupConfiguration, URLTypeOption, URLGroupGenerator, URLCellDataParser>;

pub type URLGroupContext = GroupContext<URLGroupConfiguration>;

impl GroupCustomize for URLGroupController {
  type CellData = URLCellDataPB;

  fn placeholder_cell(&self) -> Option<Cell> {
    Some(
      new_cell_builder(FieldType::URL)
        .insert_str_value("data", "")
        .build(),
    )
  }

  fn can_group(&self, content: &str, cell_data: &Self::CellData) -> bool {
    cell_data.content == content
  }

  fn create_or_delete_group_when_cell_changed(
    &mut self,
    row: &Row,
    _old_cell_data: Option<&Self::CellData>,
    _cell_data: &Self::CellData,
  ) -> FlowyResult<(Option<InsertedGroupPB>, Option<GroupPB>)> {
    // Just return if the group with this url already exists
    let mut inserted_group = None;
    if self.context.get_group(&_cell_data.url).is_none() {
      let cell_data: URLCellData = _cell_data.clone().into();
      let group = make_group_from_url_cell(&cell_data);
      let mut new_group = self.context.add_new_group(group)?;
      new_group.group.rows.push(RowPB::from(row));
      inserted_group = Some(new_group);
    }

    // Delete the old url group if there are no rows in that group
    let deleted_group = match _old_cell_data
      .and_then(|old_cell_data| self.context.get_group(&old_cell_data.content))
    {
      None => None,
      Some((_, group)) => {
        if group.rows.len() == 1 {
          Some(group.clone())
        } else {
          None
        }
      },
    };

    let deleted_group = match deleted_group {
      None => None,
      Some(group) => {
        self.context.delete_group(&group.id)?;
        Some(GroupPB::from(group.clone()))
      },
    };

    Ok((inserted_group, deleted_group))
  }

  fn add_or_remove_row_when_cell_changed(
    &mut self,
    row: &Row,
    cell_data: &Self::CellData,
  ) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_status_groups(|group| {
      let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
      if group.id == cell_data.content {
        if !group.contains_row(&row.id) {
          changeset
            .inserted_rows
            .push(InsertedRowPB::new(RowPB::from(row)));
          group.add_row(row.clone());
        }
      } else if group.contains_row(&row.id) {
        group.remove_row(&row.id);
        changeset.deleted_rows.push(row.id.clone().into_inner());
      }

      if !changeset.is_empty() {
        changesets.push(changeset);
      }
    });
    changesets
  }

  fn delete_row(&mut self, row: &Row, _cell_data: &Self::CellData) -> Vec<GroupRowsNotificationPB> {
    let mut changesets = vec![];
    self.context.iter_mut_groups(|group| {
      let mut changeset = GroupRowsNotificationPB::new(group.id.clone());
      if group.contains_row(&row.id) {
        group.remove_row(&row.id);
        changeset.deleted_rows.push(row.id.clone().into_inner());
      }

      if !changeset.is_empty() {
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

  fn delete_group_when_move_row(
    &mut self,
    _row: &Row,
    _cell_data: &Self::CellData,
  ) -> Option<GroupPB> {
    let mut deleted_group = None;
    if let Some((_, group)) = self.context.get_group(&_cell_data.content) {
      if group.rows.len() == 1 {
        deleted_group = Some(GroupPB::from(group.clone()));
      }
    }
    if deleted_group.is_some() {
      let _ = self
        .context
        .delete_group(&deleted_group.as_ref().unwrap().group_id);
    }
    deleted_group
  }
}

impl GroupController for URLGroupController {
  fn did_update_field_type_option(&mut self, _field: &Arc<Field>) {}

  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str) {
    match self.context.get_group(group_id) {
      None => tracing::warn!("Can not find the group: {}", group_id),
      Some((_, group)) => {
        let cell = insert_url_cell(group.id.clone(), field);
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

pub struct URLGroupGenerator();
impl GroupsBuilder for URLGroupGenerator {
  type Context = URLGroupContext;
  type TypeOptionType = URLTypeOption;

  fn build(
    field: &Field,
    context: &Self::Context,
    _type_option: &Option<Self::TypeOptionType>,
  ) -> GeneratedGroups {
    // Read all the cells for the grouping field
    let cells = futures::executor::block_on(context.get_all_cells());

    // Generate the groups
    let group_configs = cells
      .into_iter()
      .flat_map(|value| value.into_url_field_cell_data())
      .filter(|cell| !cell.data.is_empty())
      .map(|cell| GeneratedGroupConfig {
        group: make_group_from_url_cell(&cell),
        filter_content: cell.data,
      })
      .collect();

    let no_status_group = Some(make_no_status_group(field));
    GeneratedGroups {
      no_status_group,
      group_configs,
    }
  }
}

fn make_group_from_url_cell(cell: &URLCellData) -> Group {
  let group_id = cell.data.clone();
  let group_name = cell.data.clone();
  Group::new(group_id, group_name)
}
