use std::marker::PhantomData;
use std::sync::Arc;

use async_trait::async_trait;
use collab_database::fields::{Field, TypeOptionData};
use collab_database::rows::{Cells, Row, RowDetail, RowId};
use futures::executor::block_on;
use serde::de::DeserializeOwned;
use serde::Serialize;

use flowy_error::FlowyResult;

use crate::entities::{
  FieldType, GroupChangesPB, GroupPB, GroupRowsNotificationPB, InsertedGroupPB, InsertedRowPB,
  RowMetaPB,
};
use crate::services::cell::{get_cell_protobuf, CellProtobufBlobParser};
use crate::services::field::{default_type_option_data_from_type, TypeOption, TypeOptionCellData};
use crate::services::group::action::{
  DidMoveGroupRowResult, DidUpdateGroupRowResult, GroupControllerOperation, GroupCustomize,
};
use crate::services::group::configuration::GroupContext;
use crate::services::group::entities::GroupData;
use crate::services::group::{GroupChangeset, GroupChangesets, GroupsBuilder, MoveGroupRowContext};

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
  fn did_update_field_type_option(&mut self, field: &Field);

  /// Called before the row was created.
  fn will_create_row(&mut self, cells: &mut Cells, field: &Field, group_id: &str);
}

#[async_trait]
pub trait GroupOperationInterceptor {
  type GroupTypeOption: TypeOption;
  async fn type_option_from_group_changeset(
    &self,
    _changeset: &GroupChangeset,
    _type_option: &Self::GroupTypeOption,
    _view_id: &str,
  ) -> Option<TypeOptionData> {
    None
  }
}

/// C: represents the group configuration that impl [GroupConfigurationSerde]
/// T: the type-option data deserializer that impl [TypeOptionDataDeserializer]
/// G: the group generator, [GroupsBuilder]
/// P: the parser that impl [CellProtobufBlobParser] for the CellBytes
pub struct BaseGroupController<C, T, G, P, I> {
  pub grouping_field_id: String,
  pub type_option: T,
  pub context: GroupContext<C>,
  group_builder_phantom: PhantomData<G>,
  cell_parser_phantom: PhantomData<P>,
  pub operation_interceptor: I,
}

impl<C, T, G, P, I> BaseGroupController<C, T, G, P, I>
where
  C: Serialize + DeserializeOwned,
  T: TypeOption + From<TypeOptionData> + Send + Sync,
  G: GroupsBuilder<Context = GroupContext<C>, GroupTypeOption = T>,
  I: GroupOperationInterceptor<GroupTypeOption = T> + Send + Sync,
{
  pub async fn new(
    grouping_field: &Arc<Field>,
    mut configuration: GroupContext<C>,
    operation_interceptor: I,
  ) -> FlowyResult<Self> {
    let field_type = FieldType::from(grouping_field.field_type);
    let type_option = grouping_field
      .get_type_option::<T>(&field_type)
      .unwrap_or_else(|| T::from(default_type_option_data_from_type(&field_type)));

    // TODO(nathan): remove block_on
    let generated_groups = block_on(G::build(grouping_field, &configuration, &type_option));
    let _ = configuration.init_groups(generated_groups)?;

    Ok(Self {
      grouping_field_id: grouping_field.id.clone(),
      type_option,
      context: configuration,
      group_builder_phantom: PhantomData,
      cell_parser_phantom: PhantomData,
      operation_interceptor,
    })
  }

  fn update_no_status_group(
    &mut self,
    row_detail: &RowDetail,
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
          .any(|inserted_row| &inserted_row.row_meta.id == row_id)
      })
      .collect::<Vec<String>>();

    let mut changeset = GroupRowsNotificationPB::new(no_status_group.id.clone());
    if !no_status_group_rows.is_empty() {
      changeset
        .inserted_rows
        .push(InsertedRowPB::new(RowMetaPB::from(row_detail)));
      no_status_group.add_row(row_detail.clone());
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
    for row_detail in &no_status_group.rows {
      let row_id = row_detail.row.id.to_string();
      if default_group_deleted_rows
        .iter()
        .any(|deleted_row| deleted_row.row_meta.id == row_id)
      {
        deleted_row_ids.push(row_id);
      }
    }
    no_status_group
      .rows
      .retain(|row_detail| !deleted_row_ids.contains(&row_detail.row.id));
    changeset.deleted_rows.extend(deleted_row_ids);
    Some(changeset)
  }
}

#[async_trait]
impl<C, T, G, P, I> GroupControllerOperation for BaseGroupController<C, T, G, P, I>
where
  P: CellProtobufBlobParser<Object = <T as TypeOption>::CellProtobufType>,
  C: Serialize + DeserializeOwned + Sync + Send,
  T: TypeOption + From<TypeOptionData> + Send + Sync,
  G: GroupsBuilder<Context = GroupContext<C>, GroupTypeOption = T>,
  I: GroupOperationInterceptor<GroupTypeOption = T> + Send + Sync,
  Self: GroupCustomize<GroupTypeOption = T>,
{
  fn field_id(&self) -> &str {
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
  fn fill_groups(&mut self, rows: &[&RowDetail], _field: &Field) -> FlowyResult<()> {
    for row_detail in rows {
      let cell = match row_detail.row.cells.get(&self.grouping_field_id) {
        None => self.placeholder_cell(),
        Some(cell) => Some(cell.clone()),
      };

      if let Some(cell) = cell {
        let mut grouped_rows: Vec<GroupedRow> = vec![];
        let cell_data = <T as TypeOption>::CellData::from(&cell);
        for group in self.context.groups() {
          if self.can_group(&group.filter_content, &cell_data) {
            grouped_rows.push(GroupedRow {
              row_detail: (*row_detail).clone(),
              group_id: group.id.clone(),
            });
          }
        }

        if !grouped_rows.is_empty() {
          for group_row in grouped_rows {
            if let Some(group) = self.context.get_mut_group(&group_row.group_id) {
              group.add_row(group_row.row_detail);
            }
          }
          continue;
        }
      }

      match self.context.get_mut_no_status_group() {
        None => {},
        Some(no_status_group) => no_status_group.add_row((*row_detail).clone()),
      }
    }

    tracing::Span::current().record("group_result", format!("{},", self.context,).as_str());
    Ok(())
  }

  fn create_group(
    &mut self,
    name: String,
  ) -> FlowyResult<(Option<TypeOptionData>, Option<InsertedGroupPB>)> {
    self.generate_new_group(name)
  }

  fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
    self.context.move_group(from_group_id, to_group_id)
  }

  fn did_create_row(
    &mut self,
    row_detail: &RowDetail,
    index: usize,
  ) -> Vec<GroupRowsNotificationPB> {
    let cell = match row_detail.row.cells.get(&self.grouping_field_id) {
      None => self.placeholder_cell(),
      Some(cell) => Some(cell.clone()),
    };

    let mut changesets: Vec<GroupRowsNotificationPB> = vec![];
    if let Some(cell) = cell {
      let cell_data = <T as TypeOption>::CellData::from(&cell);

      let mut suitable_group_ids = vec![];

      for group in self.get_all_groups() {
        if self.can_group(&group.filter_content, &cell_data) {
          suitable_group_ids.push(group.id.clone());
          let changeset = GroupRowsNotificationPB::insert(
            group.id.clone(),
            vec![InsertedRowPB {
              row_meta: row_detail.into(),
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
            group.add_row(row_detail.clone());
          }
        }
      } else if let Some(no_status_group) = self.context.get_mut_no_status_group() {
        no_status_group.add_row(row_detail.clone());
        let changeset = GroupRowsNotificationPB::insert(
          no_status_group.id.clone(),
          vec![InsertedRowPB {
            row_meta: row_detail.into(),
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
    old_row_detail: &Option<RowDetail>,
    row_detail: &RowDetail,
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

    if let Some(cell_data) = get_cell_data_from_row::<P>(Some(&row_detail.row), field) {
      let _old_row = old_row_detail.as_ref();
      let old_cell_data =
        get_cell_data_from_row::<P>(old_row_detail.as_ref().map(|detail| &detail.row), field);
      if let Ok((insert, delete)) = self.create_or_delete_group_when_cell_changed(
        row_detail,
        old_cell_data.as_ref(),
        &cell_data,
      ) {
        result.inserted_group = insert;
        result.deleted_group = delete;
      }

      let mut changesets = self.add_or_remove_row_when_cell_changed(row_detail, &cell_data);
      if let Some(changeset) = self.update_no_status_group(row_detail, &changesets) {
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
    let cell = match context.row_detail.row.cells.get(&self.grouping_field_id) {
      Some(cell) => Some(cell.clone()),
      None => self.placeholder_cell(),
    };

    if let Some(cell) = cell {
      let cell_bytes = get_cell_protobuf(&cell, context.field, None);
      let cell_data = cell_bytes.parser::<P>()?;
      result.deleted_group = self.delete_group_when_move_row(&context.row_detail.row, &cell_data);
      result.row_changesets = self.move_row(&cell_data, context);
    } else {
      tracing::warn!("Unexpected moving group row, changes should not be empty");
    }
    Ok(result)
  }

  fn did_update_group_field(&mut self, _field: &Field) -> FlowyResult<Option<GroupChangesPB>> {
    Ok(None)
  }

  fn delete_group(&mut self, group_id: &str) -> FlowyResult<(Vec<RowId>, Option<TypeOptionData>)> {
    let group = if group_id != self.field_id() {
      self.get_group(group_id)
    } else {
      None
    };

    match group {
      Some((_index, group_data)) => {
        let row_ids = group_data
          .rows
          .iter()
          .map(|row| row.row.id.clone())
          .collect();
        let type_option_data = self.delete_group_custom(group_id)?;
        Ok((row_ids, type_option_data))
      },
      None => Ok((vec![], None)),
    }
  }

  async fn apply_group_changeset(
    &mut self,
    changeset: &GroupChangesets,
  ) -> FlowyResult<(Vec<GroupPB>, TypeOptionData)> {
    for group_changeset in changeset.changesets.iter() {
      self.context.update_group(group_changeset)?;
    }
    let mut type_option_data = TypeOptionData::new();
    for group_changeset in changeset.changesets.iter() {
      if let Some(new_type_option_data) = self
        .operation_interceptor
        .type_option_from_group_changeset(group_changeset, &self.type_option, &self.context.view_id)
        .await
      {
        type_option_data.extend(new_type_option_data);
      }
    }
    let updated_groups = changeset
      .changesets
      .iter()
      .filter_map(|changeset| {
        self
          .get_group(&changeset.group_id)
          .map(|(_, group)| GroupPB::from(group))
      })
      .collect::<Vec<_>>();
    Ok((updated_groups, type_option_data))
  }
}

struct GroupedRow {
  row_detail: RowDetail,
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
