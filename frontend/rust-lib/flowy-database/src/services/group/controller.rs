use crate::entities::{GroupChangesetPB, GroupRowsNotificationPB, InsertedRowPB, RowPB};
use crate::services::cell::{get_type_cell_protobuf, CellProtobufBlobParser, DecodedCellData};

use crate::services::group::action::{
    DidMoveGroupRowResult, DidUpdateGroupRowResult, GroupControllerActions, GroupCustomize,
};
use crate::services::group::configuration::GroupContext;
use crate::services::group::entities::Group;
use flowy_error::FlowyResult;
use grid_model::{
    CellRevision, FieldRevision, GroupConfigurationContentSerde, GroupRevision, RowChangeset, RowRevision,
    TypeOptionDataDeserializer,
};
use std::marker::PhantomData;
use std::sync::Arc;

/// The [GroupController] trait defines the group actions, including create/delete/move items
/// For example, the group will insert a item if the one of the new [RowRevision]'s [CellRevision]s
/// content match the group filter.
///  
/// Different [FieldType] has a different controller that implements the [GroupController] trait.
/// If the [FieldType] doesn't implement its group controller, then the [DefaultGroupController] will
/// be used.
///
pub trait GroupController: GroupControllerActions + Send + Sync {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str);
    fn did_create_row(&mut self, row_pb: &RowPB, group_id: &str);
}

/// The [GroupGenerator] trait is used to generate the groups for different [FieldType]
pub trait GroupGenerator {
    type Context;
    type TypeOptionType;

    fn generate_groups(
        field_rev: &FieldRevision,
        group_ctx: &Self::Context,
        type_option: &Option<Self::TypeOptionType>,
    ) -> GeneratedGroupContext;
}

pub struct GeneratedGroupContext {
    pub no_status_group: Option<GroupRevision>,
    pub group_configs: Vec<GeneratedGroupConfig>,
}

pub struct GeneratedGroupConfig {
    pub group_rev: GroupRevision,
    pub filter_content: String,
}

pub struct MoveGroupRowContext<'a> {
    pub row_rev: &'a RowRevision,
    pub row_changeset: &'a mut RowChangeset,
    pub field_rev: &'a FieldRevision,
    pub to_group_id: &'a str,
    pub to_row_id: Option<String>,
}
/// C: represents the group configuration that impl [GroupConfigurationSerde]
/// T: the type-option data deserializer that impl [TypeOptionDataDeserializer]
/// G: the group generator, [GroupGenerator]
/// P: the parser that impl [CellProtobufBlobParser] for the CellBytes
pub struct GenericGroupController<C, T, G, P> {
    pub field_id: String,
    pub type_option: Option<T>,
    pub group_ctx: GroupContext<C>,
    group_action_phantom: PhantomData<G>,
    cell_parser_phantom: PhantomData<P>,
}

impl<C, T, G, P> GenericGroupController<C, T, G, P>
where
    C: GroupConfigurationContentSerde,
    T: TypeOptionDataDeserializer,
    G: GroupGenerator<Context = GroupContext<C>, TypeOptionType = T>,
{
    pub async fn new(field_rev: &Arc<FieldRevision>, mut configuration: GroupContext<C>) -> FlowyResult<Self> {
        let type_option = field_rev.get_type_option::<T>(field_rev.ty);
        let generated_group_context = G::generate_groups(field_rev, &configuration, &type_option);
        let _ = configuration.init_groups(generated_group_context)?;

        Ok(Self {
            field_id: field_rev.id.clone(),
            type_option,
            group_ctx: configuration,
            group_action_phantom: PhantomData,
            cell_parser_phantom: PhantomData,
        })
    }

    // https://stackoverflow.com/questions/69413164/how-to-fix-this-clippy-warning-needless-collect
    #[allow(clippy::needless_collect)]
    fn update_no_status_group(
        &mut self,
        row_rev: &RowRevision,
        other_group_changesets: &[GroupRowsNotificationPB],
    ) -> Option<GroupRowsNotificationPB> {
        let no_status_group = self.group_ctx.get_mut_no_status_group()?;

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
            changeset.inserted_rows.push(InsertedRowPB::new(row_rev.into()));
            no_status_group.add_row(row_rev.into());
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
                let inserted_row_id = &inserted_row.row.id;
                !other_group_delete_rows.iter().any(|row_id| inserted_row_id == row_id)
            })
            .collect::<Vec<&InsertedRowPB>>();

        let mut deleted_row_ids = vec![];
        for row in &no_status_group.rows {
            if default_group_deleted_rows
                .iter()
                .any(|deleted_row| deleted_row.row.id == row.id)
            {
                deleted_row_ids.push(row.id.clone());
            }
        }
        no_status_group.rows.retain(|row| !deleted_row_ids.contains(&row.id));
        changeset.deleted_rows.extend(deleted_row_ids);
        Some(changeset)
    }
}

impl<C, T, G, P> GroupControllerActions for GenericGroupController<C, T, G, P>
where
    P: CellProtobufBlobParser,
    C: GroupConfigurationContentSerde,
    T: TypeOptionDataDeserializer,
    G: GroupGenerator<Context = GroupContext<C>, TypeOptionType = T>,

    Self: GroupCustomize<CellData = P::Object>,
{
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn groups(&self) -> Vec<&Group> {
        self.group_ctx.groups()
    }

    fn get_group(&self, group_id: &str) -> Option<(usize, Group)> {
        let group = self.group_ctx.get_group(group_id)?;
        Some((group.0, group.1.clone()))
    }

    #[tracing::instrument(level = "trace", skip_all, fields(row_count=%row_revs.len(), group_result))]
    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
        for row_rev in row_revs {
            let cell_rev = match row_rev.cells.get(&self.field_id) {
                None => self.placeholder_cell(),
                Some(cell_rev) => Some(cell_rev.clone()),
            };

            if let Some(cell_rev) = cell_rev {
                let mut grouped_rows: Vec<GroupedRow> = vec![];
                let cell_bytes = get_type_cell_protobuf(cell_rev.type_cell_data, field_rev, None).1;
                let cell_data = cell_bytes.parser::<P>()?;
                for group in self.group_ctx.groups() {
                    if self.can_group(&group.filter_content, &cell_data) {
                        grouped_rows.push(GroupedRow {
                            row: row_rev.into(),
                            group_id: group.id.clone(),
                        });
                    }
                }

                if !grouped_rows.is_empty() {
                    for group_row in grouped_rows {
                        if let Some(group) = self.group_ctx.get_mut_group(&group_row.group_id) {
                            group.add_row(group_row.row);
                        }
                    }
                    continue;
                }
            }
            match self.group_ctx.get_mut_no_status_group() {
                None => {}
                Some(no_status_group) => no_status_group.add_row(row_rev.into()),
            }
        }

        tracing::Span::current().record("group_result", format!("{},", self.group_ctx,).as_str());
        Ok(())
    }

    fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
        self.group_ctx.move_group(from_group_id, to_group_id)
    }

    fn did_update_group_row(
        &mut self,
        old_row_rev: &Option<Arc<RowRevision>>,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
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

        if let Some(cell_data) = get_cell_data_from_row_rev::<P>(Some(row_rev), field_rev) {
            let old_row_rev = old_row_rev.as_ref().map(|old| old.as_ref());
            let old_cell_data = get_cell_data_from_row_rev::<P>(old_row_rev, field_rev);
            if let Ok((insert, delete)) =
                self.create_or_delete_group_when_cell_changed(row_rev, old_cell_data.as_ref(), &cell_data)
            {
                result.inserted_group = insert;
                result.deleted_group = delete;
            }

            let mut changesets = self.add_or_remove_row_when_cell_changed(row_rev, &cell_data);
            if let Some(changeset) = self.update_no_status_group(row_rev, &changesets) {
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
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<DidMoveGroupRowResult> {
        // if the cell_rev is none, then the row must in the default group.
        let mut result = DidMoveGroupRowResult {
            deleted_group: None,
            row_changesets: vec![],
        };
        if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
            let cell_bytes = get_type_cell_protobuf(cell_rev.type_cell_data.clone(), field_rev, None).1;
            let cell_data = cell_bytes.parser::<P>()?;
            if !cell_data.is_empty() {
                tracing::error!("did_delete_delete_row {:?}", cell_rev.type_cell_data);
                result.row_changesets = self.delete_row(row_rev, &cell_data);
                return Ok(result);
            }
        }

        match self.group_ctx.get_no_status_group() {
            None => {
                tracing::error!("Unexpected None value. It should have the no status group");
            }
            Some(no_status_group) => {
                if !no_status_group.contains_row(&row_rev.id) {
                    tracing::error!("The row: {} should be in the no status group", row_rev.id);
                }
                result.row_changesets = vec![GroupRowsNotificationPB::delete(
                    no_status_group.id.clone(),
                    vec![row_rev.id.clone()],
                )];
            }
        }
        Ok(result)
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<DidMoveGroupRowResult> {
        let mut result = DidMoveGroupRowResult {
            deleted_group: None,
            row_changesets: vec![],
        };
        let cell_rev = match context.row_rev.cells.get(&self.field_id) {
            Some(cell_rev) => Some(cell_rev.clone()),
            None => self.placeholder_cell(),
        };

        if let Some(cell_rev) = cell_rev {
            let cell_bytes = get_type_cell_protobuf(cell_rev.type_cell_data, context.field_rev, None).1;
            let cell_data = cell_bytes.parser::<P>()?;
            result.deleted_group = self.delete_group_when_move_row(context.row_rev, &cell_data);
            result.row_changesets = self.move_row(&cell_data, context);
        } else {
            tracing::warn!("Unexpected moving group row, changes should not be empty");
        }
        Ok(result)
    }

    fn did_update_group_field(&mut self, _field_rev: &FieldRevision) -> FlowyResult<Option<GroupChangesetPB>> {
        Ok(None)
    }
}

struct GroupedRow {
    row: RowPB,
    group_id: String,
}

fn get_cell_data_from_row_rev<P: CellProtobufBlobParser>(
    row_rev: Option<&RowRevision>,
    field_rev: &FieldRevision,
) -> Option<P::Object> {
    let cell_rev: &CellRevision = row_rev.and_then(|row_rev| row_rev.cells.get(&field_rev.id))?;
    let cell_bytes = get_type_cell_protobuf(cell_rev.type_cell_data.clone(), field_rev, None).1;
    cell_bytes.parser::<P>().ok()
}
