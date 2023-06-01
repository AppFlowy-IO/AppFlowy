use std::collections::HashMap;
use std::marker::PhantomData;
use std::sync::Arc;

use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cell, Cells, Row, RowId};
use serde::de::DeserializeOwned;
use serde::Serialize;

use flowy_error::FlowyResult;

use crate::entities::{FieldType, GroupChangesPB, GroupRowsNotificationPB, InsertedRowPB};
use crate::services::cell::{get_cell_protobuf, CellProtobufBlobParser, DecodedCellData};
use crate::services::group::action::{
  DidMoveGroupRowResult, DidUpdateGroupRowResult, GroupControllerOperation, GroupCustomize,
};
use crate::services::group::configuration::GroupContext;
use crate::services::group::entities::GroupData;
use crate::services::group::{Group, GroupSettingChangeset};

// use collab_database::views::Group;

/// The [GroupController] trait defines the group actions, including create/delete/move items
/// For example, the group will insert a item if the one of the new [RowRevision]'s [CellRevision]s
/// content match the group filter.
///  
/// Different [FieldType] has a different controller that implements the [GroupController] trait.
/// If the [FieldType] doesn't implement its group controller, then the [DefaultGroupController] will
/// be used.
///
pub trait GroupController: GroupControllerOperation + Send + Sync {
  /// Called when the type option of the [Field] was updated.
  fn did_update_field_type_option(&mut self, field: &Arc<Field>);

  /// Called before the row was created.
  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str);

  /// Called after the row was created.
  fn did_create_row(&mut self, row: &Row, group_id: &str);
}

/// The [GroupsBuilder] trait is used to generate the groups for different [FieldType]
pub trait GroupsBuilder {
  type Context;
  type TypeOptionType;

  fn build(
    field: &Field,
    context: &Self::Context,
    type_option: &Option<Self::TypeOptionType>,
  ) -> GeneratedGroups;
}

pub struct GeneratedGroups {
  pub no_status_group: Option<Group>,
  pub group_configs: Vec<GeneratedGroupConfig>,
}

pub struct GeneratedGroupConfig {
  pub group: Group,
  pub filter_content: String,
}

pub struct MoveGroupRowContext<'a> {
  pub row: &'a Row,
  pub row_changeset: &'a mut RowChangeset,
  pub field: &'a Field,
  pub to_group_id: &'a str,
  pub to_row_id: Option<RowId>,
}

#[derive(Debug, Clone)]
pub struct RowChangeset {
  pub row_id: RowId,
  pub height: Option<i32>,
  pub visibility: Option<bool>,
  // Contains the key/value changes represents as the update of the cells. For example,
  // if there is one cell was changed, then the `cell_by_field_id` will only have one key/value.
  pub cell_by_field_id: HashMap<String, Cell>,
}

impl RowChangeset {
  pub fn new(row_id: RowId) -> Self {
    Self {
      row_id,
      height: None,
      visibility: None,
      cell_by_field_id: Default::default(),
    }
  }

  pub fn is_empty(&self) -> bool {
    self.height.is_none() && self.visibility.is_none() && self.cell_by_field_id.is_empty()
  }
}

/// C: represents the group configuration that impl [GroupConfigurationSerde]
/// T: the type-option data deserializer that impl [TypeOptionDataDeserializer]
/// G: the group generator, [GroupsBuilder]
/// P: the parser that impl [CellProtobufBlobParser] for the CellBytes
pub struct BaseGroupController<C, T, G, P> {
  pub grouping_field_id: String,
  pub type_option: Option<T>,
  pub context: GroupContext<C>,
  group_action_phantom: PhantomData<G>,
  cell_parser_phantom: PhantomData<P>,
}

impl<C, T, G, P> BaseGroupController<C, T, G, P>
where
  C: Serialize + DeserializeOwned,
  T: From<TypeOptionData>,
  G: GroupsBuilder<Context = GroupContext<C>, TypeOptionType = T>,
{
  pub async fn new(
    grouping_field: &Arc<Field>,
    mut configuration: GroupContext<C>,
  ) -> FlowyResult<Self> {
    let field_type = FieldType::from(grouping_field.field_type);
    let type_option = grouping_field.get_type_option::<T>(field_type);
    let generated_groups = G::build(grouping_field, &configuration, &type_option);
    let _ = configuration.init_groups(generated_groups)?;

    Ok(Self {
      grouping_field_id: grouping_field.id.clone(),
      type_option,
      context: configuration,
      group_action_phantom: PhantomData,
      cell_parser_phantom: PhantomData,
    })
  }

  // https://stackoverflow.com/questions/69413164/how-to-fix-this-clippy-warning-needless-collect
  #[allow(clippy::needless_collect)]
  fn update_no_status_group(
    &mut self,
    row: &Row,
    other_group_changesets: &[GroupRowsNotificationPB],
  ) -> Option<GroupRowsNotificationPB> {
    let no_status_group = self.context.get_mut_no_status_group()?;

    // [other_group_inserted_row] contains all the inserted rows except the default group.
    let other_group_inserted_row = other_group_changesets
      .iter()
      .flat_map(|changeset| &changeset.inserted_rows)
      .collect::<Vec<&InsertedRowPB>>();

    // Calculate the inserted_rows of the default_group
    let no_status_group_rows = other_group_changesets
      .iter()
      .flat_map(|changeset| &changeset.deleted_rows)
      .cloned()
      .filter(|row_id| {
        // if the [other_group_inserted_row] contains the row_id of the row
        // which means the row should not move to the default group.
        !other_group_inserted_row
          .iter()
          .any(|inserted_row| &inserted_row.row.id == row_id)
      })
      .collect::<Vec<String>>();

    let mut changeset = GroupRowsNotificationPB::new(no_status_group.id.clone());
    if !no_status_group_rows.is_empty() {
      changeset.inserted_rows.push(InsertedRowPB::new(row.into()));
      no_status_group.add_row(row.clone());
    }

    // [other_group_delete_rows] contains all the deleted rows except the default group.
    let other_group_delete_rows: Vec<String> = other_group_changesets
      .iter()
      .flat_map(|changeset| &changeset.deleted_rows)
      .cloned()
      .collect();

    let default_group_deleted_rows = other_group_changesets
      .iter()
      .flat_map(|changeset| &changeset.inserted_rows)
      .filter(|inserted_row| {
        // if the [other_group_delete_rows] contain the inserted_row, which means this row should move
        // out from the default_group.
        !other_group_delete_rows
          .iter()
          .any(|row_id| &inserted_row.row.id == row_id)
      })
      .collect::<Vec<&InsertedRowPB>>();

    let mut deleted_row_ids = vec![];
    for row in &no_status_group.rows {
      let row_id = row.id.clone().into_inner();
      if default_group_deleted_rows
        .iter()
        .any(|deleted_row| deleted_row.row.id == row_id)
      {
        deleted_row_ids.push(row_id);
      }
    }
    no_status_group
      .rows
      .retain(|row| !deleted_row_ids.contains(&row.id));
    changeset.deleted_rows.extend(deleted_row_ids);
    Some(changeset)
  }
}

impl<C, T, G, P> GroupControllerOperation for BaseGroupController<C, T, G, P>
where
  P: CellProtobufBlobParser,
  C: Serialize + DeserializeOwned,
  T: From<TypeOptionData>,
  G: GroupsBuilder<Context = GroupContext<C>, TypeOptionType = T>,

  Self: GroupCustomize<CellData = P::Object>,
{
  fn field_id(&self) -> &str {
    &self.grouping_field_id
  }

  fn groups(&self) -> Vec<&GroupData> {
    self.context.groups()
  }

  fn get_group(&self, group_id: &str) -> Option<(usize, GroupData)> {
    let group = self.context.get_group(group_id)?;
    Some((group.0, group.1.clone()))
  }

  #[tracing::instrument(level = "trace", skip_all, fields(row_count=%rows.len(), group_result))]
  fn fill_groups(&mut self, rows: &[&Row], field: &Field) -> FlowyResult<()> {
    for row in rows {
      let cell = match row.cells.get(&self.grouping_field_id) {
        None => self.placeholder_cell(),
        Some(cell) => Some(cell.clone()),
      };

      if let Some(cell) = cell {
        let mut grouped_rows: Vec<GroupedRow> = vec![];
        let cell_bytes = get_cell_protobuf(&cell, field, None);
        let cell_data = cell_bytes.parser::<P>()?;
        for group in self.context.groups() {
          if self.can_group(&group.filter_content, &cell_data) {
            grouped_rows.push(GroupedRow {
              row: (*row).clone(),
              group_id: group.id.clone(),
            });
          }
        }

        if !grouped_rows.is_empty() {
          for group_row in grouped_rows {
            if let Some(group) = self.context.get_mut_group(&group_row.group_id) {
              group.add_row(group_row.row);
            }
          }
          continue;
        }
      }

      match self.context.get_mut_no_status_group() {
        None => {},
        Some(no_status_group) => no_status_group.add_row((*row).clone()),
      }
    }

    tracing::Span::current().record("group_result", format!("{},", self.context,).as_str());
    Ok(())
  }

  fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
    self.context.move_group(from_group_id, to_group_id)
  }

  fn did_update_group_row(
    &mut self,
    old_row: &Option<Row>,
    row: &Row,
    field: &Field,
  ) -> FlowyResult<DidUpdateGroupRowResult> {
    // let cell_data = row_rev.cells.get(&self.field_id).and_then(|cell_rev| {
    //     let cell_data: Option<P> = get_type_cell_data(cell_rev, field_rev, None);
    //     cell_data
    // });
    let mut result = DidUpdateGroupRowResult {
      inserted_group: None,
      deleted_group: None,
      row_changesets: vec![],
    };

    if let Some(cell_data) = get_cell_data_from_row::<P>(Some(row), field) {
      let old_row = old_row.as_ref();
      let old_cell_data = get_cell_data_from_row::<P>(old_row, field);
      if let Ok((insert, delete)) =
        self.create_or_delete_group_when_cell_changed(row, old_cell_data.as_ref(), &cell_data)
      {
        result.inserted_group = insert;
        result.deleted_group = delete;
      }

      let mut changesets = self.add_or_remove_row_when_cell_changed(row, &cell_data);
      if let Some(changeset) = self.update_no_status_group(row, &changesets) {
        if !changeset.is_empty() {
          changesets.push(changeset);
        }
      }
      result.row_changesets = changesets;
    }

    Ok(result)
  }

  fn did_delete_delete_row(
    &mut self,
    row: &Row,
    field: &Field,
  ) -> FlowyResult<DidMoveGroupRowResult> {
    // if the cell_rev is none, then the row must in the default group.
    let mut result = DidMoveGroupRowResult {
      deleted_group: None,
      row_changesets: vec![],
    };
    if let Some(cell) = row.cells.get(&self.grouping_field_id) {
      let cell_bytes = get_cell_protobuf(cell, field, None);
      let cell_data = cell_bytes.parser::<P>()?;
      if !cell_data.is_empty() {
        tracing::error!("did_delete_delete_row {:?}", cell);
        result.row_changesets = self.delete_row(row, &cell_data);
        return Ok(result);
      }
    }

    match self.context.get_no_status_group() {
      None => {
        tracing::error!("Unexpected None value. It should have the no status group");
      },
      Some(no_status_group) => {
        if !no_status_group.contains_row(&row.id) {
          tracing::error!("The row: {:?} should be in the no status group", row.id);
        }
        result.row_changesets = vec![GroupRowsNotificationPB::delete(
          no_status_group.id.clone(),
          vec![row.id.clone().into_inner()],
        )];
      },
    }
    Ok(result)
  }

  #[tracing::instrument(level = "trace", skip_all, err)]
  fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<DidMoveGroupRowResult> {
    let mut result = DidMoveGroupRowResult {
      deleted_group: None,
      row_changesets: vec![],
    };
    let cell = match context.row.cells.get(&self.grouping_field_id) {
      Some(cell) => Some(cell.clone()),
      None => self.placeholder_cell(),
    };

    if let Some(cell) = cell {
      let cell_bytes = get_cell_protobuf(&cell, context.field, None);
      let cell_data = cell_bytes.parser::<P>()?;
      result.deleted_group = self.delete_group_when_move_row(context.row, &cell_data);
      result.row_changesets = self.move_row(&cell_data, context);
    } else {
      tracing::warn!("Unexpected moving group row, changes should not be empty");
    }
    Ok(result)
  }

  fn did_update_group_field(&mut self, _field: &Field) -> FlowyResult<Option<GroupChangesPB>> {
    Ok(None)
  }

  fn apply_group_setting_changeset(&mut self, changeset: GroupSettingChangeset) -> FlowyResult<()> {
    for group_changeset in changeset.update_groups {
      if let Err(e) = self.context.update_group(group_changeset) {
        tracing::error!("Failed to update group: {:?}", e);
      }
    }
    Ok(())
  }
}

struct GroupedRow {
  row: Row,
  group_id: String,
}

fn get_cell_data_from_row<P: CellProtobufBlobParser>(
  row: Option<&Row>,
  field: &Field,
) -> Option<P::Object> {
  let cell = row.and_then(|row| row.cells.get(&field.id))?;
  let cell_bytes = get_cell_protobuf(cell, field, None);
  cell_bytes.parser::<P>().ok()
}
