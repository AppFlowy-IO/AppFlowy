use crate::entities::{GroupPB, RowPB};
use crate::services::cell::{decode_any_cell_data, CellBytesParser};
use bytes::Bytes;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    FieldRevision, GroupConfigurationRevision, RowRevision, TypeOptionDataDeserializer,
};
use indexmap::IndexMap;
use std::marker::PhantomData;
use std::sync::Arc;

pub trait GroupAction {
    type CellDataType;

    fn should_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool;
}

pub trait GroupCellContentProvider {
    /// We need to group the rows base on the deduplication cell content when the field type is
    /// RichText.
    fn deduplication_cell_content(&self, _field_id: &str) -> Vec<String> {
        vec![]
    }
}

pub trait GroupGenerator {
    type ConfigurationType;
    type TypeOptionType;

    fn gen_groups(
        configuration: &Option<Self::ConfigurationType>,
        type_option: &Option<Self::TypeOptionType>,
        cell_content_provider: &dyn GroupCellContentProvider,
    ) -> Vec<Group>;
}

const DEFAULT_GROUP_ID: &str = "default_group";

pub struct GroupController<C, T, G, CP> {
    pub field_rev: Arc<FieldRevision>,
    pub groups: IndexMap<String, Group>,
    pub default_group: Group,
    pub type_option: Option<T>,
    pub configuration: Option<C>,
    group_action_phantom: PhantomData<G>,
    cell_parser_phantom: PhantomData<CP>,
}

pub struct Group {
    pub id: String,
    pub desc: String,
    pub rows: Vec<RowPB>,
    pub content: String,
}

impl std::convert::From<Group> for GroupPB {
    fn from(group: Group) -> Self {
        Self {
            group_id: group.id,
            desc: group.desc,
            rows: group.rows,
        }
    }
}

impl<C, T, G, CP> GroupController<C, T, G, CP>
where
    C: TryFrom<Bytes, Error = protobuf::ProtobufError>,
    T: TypeOptionDataDeserializer,
    G: GroupGenerator<ConfigurationType = C, TypeOptionType = T>,
{
    pub fn new(
        field_rev: Arc<FieldRevision>,
        configuration: GroupConfigurationRevision,
        cell_content_provider: &dyn GroupCellContentProvider,
    ) -> FlowyResult<Self> {
        let configuration = match configuration.content {
            None => None,
            Some(content) => Some(C::try_from(Bytes::from(content))?),
        };
        let field_type_rev = field_rev.field_type_rev;
        let type_option = field_rev.get_type_option_entry::<T>(field_type_rev);
        let groups = G::gen_groups(&configuration, &type_option, cell_content_provider);

        let default_group = Group {
            id: DEFAULT_GROUP_ID.to_owned(),
            desc: format!("No {}", field_rev.name),
            rows: vec![],
            content: "".to_string(),
        };

        Ok(Self {
            field_rev,
            groups: groups.into_iter().map(|group| (group.id.clone(), group)).collect(),
            default_group,
            type_option,
            configuration,
            group_action_phantom: PhantomData,
            cell_parser_phantom: PhantomData,
        })
    }

    pub fn take_groups(self) -> Vec<Group> {
        let default_group = self.default_group;
        let mut groups: Vec<Group> = self.groups.into_values().collect();
        if !default_group.rows.is_empty() {
            groups.push(default_group);
        }
        groups
    }
}

impl<C, T, G, CP> GroupController<C, T, G, CP>
where
    CP: CellBytesParser,
    Self: GroupAction<CellDataType = CP::Object>,
{
    pub fn group_rows(&mut self, rows: &[Arc<RowRevision>]) -> FlowyResult<()> {
        if self.configuration.is_none() {
            return Ok(());
        }
        tracing::debug!("group {} rows", rows.len());

        for row in rows {
            if let Some(cell_rev) = row.cells.get(&self.field_rev.id) {
                let mut records: Vec<GroupRecord> = vec![];

                let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), &self.field_rev);
                let cell_data = cell_bytes.parser::<CP>()?;
                for group in self.groups.values() {
                    if self.should_group(&group.content, &cell_data) {
                        records.push(GroupRecord {
                            row: row.into(),
                            group_id: group.id.clone(),
                        });
                    }
                }

                if records.is_empty() {
                    self.default_group.rows.push(row.into());
                } else {
                    for record in records {
                        if let Some(group) = self.groups.get_mut(&record.group_id) {
                            group.rows.push(record.row);
                        }
                    }
                }
            } else {
                self.default_group.rows.push(row.into());
            }
        }

        Ok(())
    }
}

struct GroupRecord {
    row: RowPB,
    group_id: String,
}
