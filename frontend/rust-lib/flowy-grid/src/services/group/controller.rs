use crate::entities::{GroupChangesetPB, GroupViewChangesetPB, InsertedRowPB, RowPB};
use crate::services::cell::{decode_any_cell_data, CellBytesParser};
use crate::services::group::action::GroupAction;
use crate::services::group::configuration::GroupContext;
use crate::services::group::entities::Group;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    FieldRevision, GroupConfigurationContentSerde, GroupRevision, RowChangeset, RowRevision, TypeOptionDataDeserializer,
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
        field_id: &str,
        group_ctx: &Self::Context,
        type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<GeneratedGroupConfig>;
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

/// Defines the shared actions each group controller can perform.
pub trait GroupControllerActions: Send + Sync {
    /// The field that is used for grouping the rows
    fn field_id(&self) -> &str;

    /// Returns number of groups the current field has
    fn groups(&self) -> Vec<Group>;

    /// Returns the index and the group data with group_id
    fn get_group(&self, group_id: &str) -> Option<(usize, Group)>;

    /// Separates the rows into different groups
    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()>;

    /// Remove the group with from_group_id and insert it to the index with to_group_id
    fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()>;

    /// Insert the row to the group if the corresponding cell data is changed
    fn did_update_group_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>>;

    /// Remove the row from the group if the corresponding cell data is changed
    fn did_delete_delete_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>>;

    /// Move the row from one group to another group
    fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<Vec<GroupChangesetPB>>;

    /// Update the group if the corresponding field is changed
    fn did_update_group_field(&mut self, field_rev: &FieldRevision) -> FlowyResult<Option<GroupViewChangesetPB>>;
}

/// C: represents the group configuration that impl [GroupConfigurationSerde]
/// T: the type-option data deserializer that impl [TypeOptionDataDeserializer]
/// G: the group generator, [GroupGenerator]
/// P: the parser that impl [CellBytesParser] for the CellBytes
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
        let groups = G::generate_groups(&field_rev.id, &configuration, &type_option);
        let _ = configuration.init_groups(groups)?;

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
    fn update_default_group(
        &mut self,
        row_rev: &RowRevision,
        other_group_changesets: &[GroupChangesetPB],
    ) -> Option<GroupChangesetPB> {
        let default_group = self.group_ctx.get_mut_no_status_group()?;

        // [other_group_inserted_row] contains all the inserted rows except the default group.
        let other_group_inserted_row = other_group_changesets
            .iter()
            .flat_map(|changeset| &changeset.inserted_rows)
            .collect::<Vec<&InsertedRowPB>>();

        // Calculate the inserted_rows of the default_group
        let default_group_inserted_row = other_group_changesets
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

        let mut changeset = GroupChangesetPB::new(default_group.id.clone());
        if !default_group_inserted_row.is_empty() {
            changeset.inserted_rows.push(InsertedRowPB::new(row_rev.into()));
            default_group.add_row(row_rev.into());
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
        for row in &default_group.rows {
            if default_group_deleted_rows
                .iter()
                .any(|deleted_row| deleted_row.row.id == row.id)
            {
                deleted_row_ids.push(row.id.clone());
            }
        }
        default_group.rows.retain(|row| !deleted_row_ids.contains(&row.id));
        changeset.deleted_rows.extend(deleted_row_ids);
        Some(changeset)
    }
}

impl<C, T, G, P> GroupControllerActions for GenericGroupController<C, T, G, P>
where
    P: CellBytesParser,
    C: GroupConfigurationContentSerde,
    T: TypeOptionDataDeserializer,
    G: GroupGenerator<Context = GroupContext<C>, TypeOptionType = T>,

    Self: GroupAction<CellDataType = P::Object>,
{
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn groups(&self) -> Vec<Group> {
        if self.use_default_group() {
            self.group_ctx.groups().into_iter().cloned().collect()
        } else {
            self.group_ctx
                .groups()
                .into_iter()
                .filter(|group| group.id != self.field_id)
                .cloned()
                .collect::<Vec<_>>()
        }
    }

    fn get_group(&self, group_id: &str) -> Option<(usize, Group)> {
        let group = self.group_ctx.get_group(group_id)?;
        Some((group.0, group.1.clone()))
    }

    #[tracing::instrument(level = "trace", skip_all, fields(row_count=%row_revs.len(), group_result))]
    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
        for row_rev in row_revs {
            let cell_rev = match row_rev.cells.get(&self.field_id) {
                None => self.default_cell_rev(),
                Some(cell_rev) => Some(cell_rev.clone()),
            };

            if let Some(cell_rev) = cell_rev {
                let mut grouped_rows: Vec<GroupedRow> = vec![];
                let cell_bytes = decode_any_cell_data(cell_rev.data, field_rev).1;
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
                Some(default_group) => default_group.add_row(row_rev.into()),
            }
        }

        tracing::Span::current().record("group_result", &format!("{},", self.group_ctx,).as_str());
        Ok(())
    }

    fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
        self.group_ctx.move_group(from_group_id, to_group_id)
    }

    fn did_update_group_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>> {
        if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
            let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev).1;
            let cell_data = cell_bytes.parser::<P>()?;
            let mut changesets = self.add_row_if_match(row_rev, &cell_data);

            if self.use_default_group() {
                if let Some(default_group_changeset) = self.update_default_group(row_rev, &changesets) {
                    tracing::trace!("default_group_changeset: {}", default_group_changeset);
                    if !default_group_changeset.is_empty() {
                        changesets.push(default_group_changeset);
                    }
                }
            }

            Ok(changesets)
        } else {
            Ok(vec![])
        }
    }

    fn did_delete_delete_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupChangesetPB>> {
        // if the cell_rev is none, then the row must be crated from the default group.
        if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
            let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev).1;
            let cell_data = cell_bytes.parser::<P>()?;
            Ok(self.remove_row_if_match(row_rev, &cell_data))
        } else if let Some(group) = self.group_ctx.get_no_status_group() {
            Ok(vec![GroupChangesetPB::delete(
                group.id.clone(),
                vec![row_rev.id.clone()],
            )])
        } else {
            Ok(vec![])
        }
    }

    #[tracing::instrument(level = "trace", skip_all, err)]
    fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<Vec<GroupChangesetPB>> {
        let cell_rev = match context.row_rev.cells.get(&self.field_id) {
            Some(cell_rev) => Some(cell_rev.clone()),
            None => self.default_cell_rev(),
        };

        if let Some(cell_rev) = cell_rev {
            let cell_bytes = decode_any_cell_data(cell_rev.data, context.field_rev).1;
            let cell_data = cell_bytes.parser::<P>()?;
            Ok(self.move_row(&cell_data, context))
        } else {
            tracing::warn!("Unexpected moving group row, changes should not be empty");
            Ok(vec![])
        }
    }

    fn did_update_group_field(&mut self, _field_rev: &FieldRevision) -> FlowyResult<Option<GroupViewChangesetPB>> {
        Ok(None)
    }
}

struct GroupedRow {
    row: RowPB,
    group_id: String,
}
