use crate::entities::{GroupRowsChangesetPB, RowPB};
use crate::services::cell::{decode_any_cell_data, CellBytesParser};
use crate::services::group::action::GroupAction;
use crate::services::group::configuration::GenericGroupConfiguration;
use crate::services::group::entities::Group;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    FieldRevision, GroupConfigurationContentSerde, RowChangeset, RowRevision, TypeOptionDataDeserializer,
};

use std::marker::PhantomData;
use std::sync::Arc;

const DEFAULT_GROUP_ID: &str = "default_group";

// Each kind of group must implement this trait to provide custom group
// operations. For example, insert cell data to the row_rev when creating
// a new row.
pub trait GroupController: GroupControllerSharedOperation + Send + Sync {
    fn will_create_row(&mut self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str);
}

pub trait GroupGenerator {
    type ConfigurationType;
    type TypeOptionType;

    fn generate_groups(
        field_id: &str,
        configuration: &Self::ConfigurationType,
        type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<Group>;
}

pub struct MoveGroupRowContext<'a> {
    pub row_rev: &'a RowRevision,
    pub row_changeset: &'a mut RowChangeset,
    pub field_rev: &'a FieldRevision,
    pub to_group_id: &'a str,
    pub to_row_id: Option<String>,
}

// Defines the shared actions each group controller can perform.
pub trait GroupControllerSharedOperation: Send + Sync {
    // The field that is used for grouping the rows
    fn field_id(&self) -> &str;
    fn groups(&self) -> Vec<Group>;
    fn get_group(&self, group_id: &str) -> Option<(usize, Group)>;
    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<Vec<Group>>;
    fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()>;
    fn did_update_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupRowsChangesetPB>>;

    fn did_delete_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupRowsChangesetPB>>;

    fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<Vec<GroupRowsChangesetPB>>;
}

/// C: represents the group configuration that impl [GroupConfigurationSerde]
/// T: the type option data deserializer that impl [TypeOptionDataDeserializer]
/// G: the group generator, [GroupGenerator]
/// P: the parser that impl [CellBytesParser] for the CellBytes
pub struct GenericGroupController<C, T, G, P> {
    pub field_id: String,
    pub type_option: Option<T>,
    pub configuration: GenericGroupConfiguration<C>,
    /// default_group is used to store the rows that don't belong to any groups.
    default_group: Group,
    group_action_phantom: PhantomData<G>,
    cell_parser_phantom: PhantomData<P>,
}

impl<C, T, G, P> GenericGroupController<C, T, G, P>
where
    C: GroupConfigurationContentSerde,
    T: TypeOptionDataDeserializer,
    G: GroupGenerator<ConfigurationType = GenericGroupConfiguration<C>, TypeOptionType = T>,
{
    pub async fn new(
        field_rev: &Arc<FieldRevision>,
        mut configuration: GenericGroupConfiguration<C>,
    ) -> FlowyResult<Self> {
        let field_type_rev = field_rev.ty;
        let type_option = field_rev.get_type_option_entry::<T>(field_type_rev);
        let groups = G::generate_groups(&field_rev.id, &configuration, &type_option);
        let _ = configuration.merge_groups(groups).await?;
        let default_group = Group::new(
            DEFAULT_GROUP_ID.to_owned(),
            field_rev.id.clone(),
            format!("No {}", field_rev.name),
            "".to_string(),
        );

        Ok(Self {
            field_id: field_rev.id.clone(),
            default_group,
            type_option,
            configuration,
            group_action_phantom: PhantomData,
            cell_parser_phantom: PhantomData,
        })
    }
}

impl<C, T, G, P> GroupControllerSharedOperation for GenericGroupController<C, T, G, P>
where
    P: CellBytesParser,
    C: GroupConfigurationContentSerde,
    Self: GroupAction<CellDataType = P::Object>,
{
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn groups(&self) -> Vec<Group> {
        self.configuration.clone_groups()
    }

    fn get_group(&self, group_id: &str) -> Option<(usize, Group)> {
        let group = self.configuration.get_group(group_id)?;
        Some((group.0, group.1.clone()))
    }

    fn fill_groups(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<Vec<Group>> {
        for row_rev in row_revs {
            if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
                let mut group_rows: Vec<GroupRow> = vec![];
                let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev);
                let cell_data = cell_bytes.parser::<P>()?;
                for group in self.configuration.groups() {
                    if self.can_group(&group.content, &cell_data) {
                        group_rows.push(GroupRow {
                            row: row_rev.into(),
                            group_id: group.id.clone(),
                        });
                    }
                }

                if group_rows.is_empty() {
                    self.default_group.add_row(row_rev.into());
                } else {
                    for group_row in group_rows {
                        if let Some(group) = self.configuration.get_mut_group(&group_row.group_id) {
                            group.add_row(group_row.row);
                        }
                    }
                }
            } else {
                self.default_group.add_row(row_rev.into());
            }
        }

        let default_group = self.default_group.clone();
        let mut groups: Vec<Group> = self.configuration.clone_groups();
        if !default_group.number_of_row() == 0 {
            groups.push(default_group);
        }

        Ok(groups)
    }

    fn move_group(&mut self, from_group_id: &str, to_group_id: &str) -> FlowyResult<()> {
        self.configuration.move_group(from_group_id, to_group_id)
    }

    fn did_update_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupRowsChangesetPB>> {
        if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
            let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev);
            let cell_data = cell_bytes.parser::<P>()?;
            Ok(self.add_row_if_match(row_rev, &cell_data))
        } else {
            Ok(vec![])
        }
    }

    fn did_delete_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupRowsChangesetPB>> {
        if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
            let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev);
            let cell_data = cell_bytes.parser::<P>()?;
            Ok(self.remove_row_if_match(row_rev, &cell_data))
        } else {
            Ok(vec![])
        }
    }

    fn move_group_row(&mut self, context: MoveGroupRowContext) -> FlowyResult<Vec<GroupRowsChangesetPB>> {
        if let Some(cell_rev) = context.row_rev.cells.get(&self.field_id) {
            let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), context.field_rev);
            let cell_data = cell_bytes.parser::<P>()?;
            Ok(self.move_row(&cell_data, context))
        } else {
            Ok(vec![])
        }
    }
}

struct GroupRow {
    row: RowPB,
    group_id: String,
}
