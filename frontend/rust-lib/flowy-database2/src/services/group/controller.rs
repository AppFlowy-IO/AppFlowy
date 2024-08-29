use async_trait::async_trait;
use std::marker::PhantomData;
use std::sync::Arc;

use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cells, Row, RowId};
use futures::executor::block_on;
use serde::de::DeserializeOwned;
use serde::Serialize;

use flowy_error::{FlowyError, FlowyResult};

use crate::entities::{
  FieldType, GroupChangesPB, GroupPB, GroupRowsNotificationPB, InsertedGroupPB, InsertedRowPB,
  RowMetaPB,
};
use crate::services::cell::{get_cell_protobuf, CellProtobufBlobParser};
use crate::services::field::{default_type_option_data_from_type, TypeOption, TypeOptionCellData};
use crate::services::group::action::{
  DidMoveGroupRowResult, DidUpdateGroupRowResult, GroupController, GroupCustomize,
};
use crate::services::group::configuration::GroupControllerContext;
use crate::services::group::entities::GroupData;
use crate::services::group::{GroupChangeset, GroupsBuilder, MoveGroupRowContext};

#[async_trait]
pub trait GroupControllerDelegate: Send + Sync + 'static {
  async fn get_field(&self, field_id: &str) -> Option<Field>;

  async fn get_all_rows(&self, view_id: &str) -> Vec<Arc<Row>>;
}

/// [BaseGroupController] is a generic group controller that provides customized implementations
/// of the `GroupController` trait for different field types.
///
/// - `C`: represents the group configuration that impl [GroupConfigurationSerde]
/// - `G`: group generator, [GroupsBuilder]
/// - `P`: parser that impl [CellProtobufBlobParser] for the CellBytes
///
/// See also: [DefaultGroupController] which contains the most basic implementation of
/// `GroupController` that only has one group.
pub struct BaseGroupController<C, G, P> {
  pub grouping_field_id: String,
  pub context: GroupControllerContext<C>,
  group_builder_phantom: PhantomData<G>,
  cell_parser_phantom: PhantomData<P>,
  pub delegate: Arc<dyn GroupControllerDelegate>,
}

impl<C, T, G, P> BaseGroupController<C, G, P>
where
  C: Serialize + DeserializeOwned,
  T: TypeOption + Send + Sync,
  G: GroupsBuilder<Context = GroupControllerContext<C>, GroupTypeOption = T>,
{
  pub async fn new(
    grouping_field: &Field,
    mut configuration: GroupControllerContext<C>,
    delegate: Arc<dyn GroupControllerDelegate>,
  ) -> FlowyResult<Self> {
    let field_type = FieldType::from(grouping_field.field_type);
    let type_option = grouping_field
      .get_type_option::<T>(&field_type)
      .unwrap_or_else(|| T::from(default_type_option_data_from_type(field_type)));

    // TODO(nathan): remove block_on
    let generated_groups = block_on(G::build(grouping_field, &configuration, &type_option));
    let _ = configuration.init_groups(generated_groups)?;

    Ok(Self {
      grouping_field_id: grouping_field.id.clone(),
      context: configuration,
      group_builder_phantom: PhantomData,
      cell_parser_phantom: PhantomData,
      delegate,
    })
  }

  pub async fn get_grouping_field_type_option(&self) -> Option<T> {
    self
      .delegate
      .get_field(&self.grouping_field_id)
      .await
      .and_then(|field| field.get_type_option::<T>(FieldType::from(field.field_type)))
  }

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
      .filter(|&row_id| {
        // if the [other_group_inserted_row] contains the row_id of the row
        // which means the row should not move to the default group.
        !other_group_inserted_row
          .iter()
          .any(|inserted_row| &inserted_row.row_meta.id == row_id)
      })
      .cloned()
      .collect::<Vec<String>>();

    let mut changeset = GroupRowsNotificationPB::new(no_status_group.id.clone());
    if !no_status_group_rows.is_empty() {
      changeset
        .inserted_rows
        .push(InsertedRowPB::new(RowMetaPB::from(row.clone())));
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
          .any(|row_id| &inserted_row.row_meta.id == row_id)
      })
      .collect::<Vec<&InsertedRowPB>>();

    let mut deleted_row_ids = vec![];
    for row in &no_status_group.rows {
      let row_id = row.id.to_string();
      if default_group_deleted_rows
        .iter()
        .any(|deleted_row| deleted_row.row_meta.id == row_id)
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

#[async_trait]
impl<C, T, G, P> GroupController for BaseGroupController<C, G, P>
where
  P: CellProtobufBlobParser<Object = <T as TypeOption>::CellProtobufType>,
  C: Serialize + DeserializeOwned + Sync + Send,
  T: TypeOption + Send + Sync,
  G: GroupsBuilder<Context = GroupControllerContext<C>, GroupTypeOption = T>,
  Self: GroupCustomize<GroupTypeOption = T>,
{
  fn get_grouping_field_id(&self) -> &str {
    &self.grouping_field_id
  }

  fn get_all_groups(&self) -> Vec<&GroupData> {
    self.context.groups()
  }

  fn get_group(&self, group_id: &str) -> Option<(usize, GroupData)> {
    let group = self.context.get_group(group_id)?;
    Some((group.0, group.1.clone()))
  }

  #[tracing::instrument(level = "trace", skip_all, fields(row_count=%rows.len(), group_result))]
  fn fill_groups(&mut self, rows: &[&Row], _field: &Field) -> FlowyResult<()> {
    for row in rows {
      let cell = match row.cells.get(&self.grouping_field_id) {
        None => self.placeholder_cell(),
        Some(cell) => Some(cell.clone()),
      };

      if let Some(cell) = cell {
        let mut grouped_rows: Vec<GroupedRow> = vec![];
        let cell_data = <T as TypeOption>::CellData::from(&cell);
        for group in self.context.groups() {
          if self.can_group(&group.id, &cell_data) {
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

  async fn create_group(
    &mut self,
    name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)> {
    <Self as GroupCustomize>::create_group(self, name).await
  }

  fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
    self.context.move_group(from_group_id, to_group_id)
  }

  fn did_create_row(&mut self, row: &Row, index: usize) -> Vec<GroupRowsNotificationPB> {
    let mut changesets: Vec<GroupRowsNotificationPB> = vec![];

    let cell = match row.cells.get(&self.grouping_field_id) {
      None => self.placeholder_cell(),
      Some(cell) => Some(cell.clone()),
    };

    if let Some(cell) = cell {
      let cell_data = <T as TypeOption>::CellData::from(&cell);

      let mut suitable_group_ids = vec![];

      for group in self.get_all_groups() {
        if self.can_group(&group.id, &cell_data) {
          suitable_group_ids.push(group.id.clone());
          let changeset = GroupRowsNotificationPB::insert(
            group.id.clone(),
            vec![InsertedRowPB {
              row_meta: (*row).clone().into(),
              index: Some(index as i32),
              is_new: true,
            }],
          );
          changesets.push(changeset);
        }
      }
      if !suitable_group_ids.is_empty() {
        for group_id in suitable_group_ids.iter() {
          if let Some(group) = self.context.get_mut_group(group_id) {
            group.add_row((*row).clone());
          }
        }
      } else if let Some(no_status_group) = self.context.get_mut_no_status_group() {
        no_status_group.add_row((*row).clone());
        let changeset = GroupRowsNotificationPB::insert(
          no_status_group.id.clone(),
          vec![InsertedRowPB {
            row_meta: (*row).clone().into(),
            index: Some(index as i32),
            is_new: true,
          }],
        );
        changesets.push(changeset);
      }
    }

    changesets
  }

  fn did_update_group_row(
    &mut self,
    old_row: &Option<Row>,
    new_row: &Row,
    field: &Field,
  ) -> FlowyResult<DidUpdateGroupRowResult> {
    let mut result = DidUpdateGroupRowResult {
      inserted_group: None,
      deleted_group: None,
      row_changesets: vec![],
    };
    if let Some(cell_data) = get_cell_data_from_row::<P>(Some(new_row), field) {
      let old_cell_data = get_cell_data_from_row::<P>(old_row.as_ref(), field);
      if let Ok((insert, delete)) =
        self.create_or_delete_group_when_cell_changed(new_row, old_cell_data.as_ref(), &cell_data)
      {
        result.inserted_group = insert;
        result.deleted_group = delete;
      }

      let mut changesets = self.add_or_remove_row_when_cell_changed(new_row, &cell_data);
      if let Some(changeset) = self.update_no_status_group(new_row, &changesets) {
        if !changeset.is_empty() {
          changesets.push(changeset);
        }
      }
      result.row_changesets = changesets;
    }

    Ok(result)
  }

  fn did_delete_row(&mut self, row: &Row) -> FlowyResult<DidMoveGroupRowResult> {
    let mut result = DidMoveGroupRowResult {
      deleted_group: None,
      row_changesets: vec![],
    };
    // early return if the row is not in the default group
    if let Some(cell) = row.cells.get(&self.grouping_field_id) {
      let cell_data = <T as TypeOption>::CellData::from(cell);
      if !cell_data.is_cell_empty() {
        (result.deleted_group, result.row_changesets) = self.delete_row(row, &cell_data);
        return Ok(result);
      }
    }

    match self.context.get_mut_no_status_group() {
      None => {
        tracing::error!("Unexpected None value. It should have the no status group");
      },
      Some(no_status_group) => {
        if !no_status_group.contains_row(&row.id) {
          tracing::error!("The row: {:?} should be in the no status group", row.id);
        }
        no_status_group.remove_row(&row.id);
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
      result.row_changesets = self.move_row(context);
    } else {
      tracing::warn!("Unexpected moving group row, changes should not be empty");
    }
    Ok(result)
  }

  fn did_update_group_field(&mut self, _field: &Field) -> FlowyResult<Option<GroupChangesPB>> {
    Ok(None)
  }

  async fn delete_group(
    &mut self,
    group_id: &str,
  ) -> FlowyResult<(Vec<RowId>, Option<TypeOptionData>)> {
    let group = if group_id != self.get_grouping_field_id() {
      self.get_group(group_id)
    } else {
      None
    };

    match group {
      Some((_index, group_data)) => {
        let row_ids = group_data.rows.iter().map(|row| row.id.clone()).collect();
        let type_option_data = <Self as GroupCustomize>::delete_group(self, group_id).await?;
        Ok((row_ids, type_option_data))
      },
      None => Ok((vec![], None)),
    }
  }

  async fn apply_group_changeset(
    &mut self,
    changeset: &[GroupChangeset],
  ) -> FlowyResult<(Vec<GroupPB>, Option<TypeOptionData>)> {
    // update group visibility
    for group_changeset in changeset.iter() {
      self.context.update_group(group_changeset)?;
    }

    // update group name
    let type_option = self.get_grouping_field_type_option().await.ok_or_else(|| {
      FlowyError::internal().with_context("Failed to get grouping field type option")
    })?;

    let mut updated_type_option = None;

    for group_changeset in changeset.iter() {
      if let Some(type_option) =
        self.update_type_option_when_update_group(group_changeset, &type_option)
      {
        updated_type_option = Some(type_option);
        break;
      }
    }

    let updated_groups = changeset
      .iter()
      .filter_map(|changeset| {
        self
          .get_group(&changeset.group_id)
          .map(|(_, group)| GroupPB::from(group))
      })
      .collect::<Vec<_>>();

    Ok((
      updated_groups,
      updated_type_option.map(|type_option| type_option.into()),
    ))
  }

  fn will_create_row(&self, cells: &mut Cells, field: &Field, group_id: &str) {
    <Self as GroupCustomize>::will_create_row(self, cells, field, group_id);
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
