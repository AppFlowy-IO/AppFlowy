use crate::entities::{GroupPB, GroupRowsChangesetPB, RowPB};
use crate::services::cell::{decode_any_cell_data, CellBytesParser};
use bytes::Bytes;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    FieldRevision, GroupConfigurationRevision, RowRevision, TypeOptionDataDeserializer,
};
use indexmap::IndexMap;
use std::marker::PhantomData;
use std::sync::Arc;

pub trait GroupGenerator {
    type ConfigurationType;
    type TypeOptionType;

    fn generate_groups(
        configuration: &Option<Self::ConfigurationType>,
        type_option: &Option<Self::TypeOptionType>,
    ) -> Vec<Group>;
}

pub trait Groupable: Send + Sync {
    type CellDataType;
    fn can_group(&self, content: &str, cell_data: &Self::CellDataType) -> bool;
    fn group_row(&mut self, row_rev: &RowRevision, cell_data: &Self::CellDataType) -> Vec<GroupRowsChangesetPB>;
}

pub trait GroupController: GroupControllerSharedAction + Send + Sync {
    fn fill_row(&self, row_rev: &mut RowRevision, field_rev: &FieldRevision, group_id: &str);
}

pub trait GroupControllerSharedAction: Send + Sync {
    // The field that is used for grouping the rows
    fn field_id(&self) -> &str;
    fn build_groups(&self) -> Vec<Group>;
    fn group_rows(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()>;
    fn did_update_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupRowsChangesetPB>>;
}

const DEFAULT_GROUP_ID: &str = "default_group";

/// C: represents the group configuration structure
/// T: the type option data deserializer that impl [TypeOptionDataDeserializer]
/// G: the group generator, [GroupGenerator]
/// P: the parser that impl [CellBytesParser] for the CellBytes
pub struct GenericGroupController<C, T, G, P> {
    pub field_id: String,
    pub groups_map: IndexMap<String, Group>,
    default_group: Group,
    pub type_option: Option<T>,
    pub configuration: Option<C>,
    group_action_phantom: PhantomData<G>,
    cell_parser_phantom: PhantomData<P>,
}

#[derive(Clone)]
pub struct Group {
    pub id: String,
    pub desc: String,
    rows: Vec<RowPB>,
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

impl Group {
    pub fn new(id: String, desc: String, content: String) -> Self {
        Self {
            id,
            desc,
            rows: vec![],
            content,
        }
    }

    pub fn contains_row(&self, row_id: &str) -> bool {
        self.rows.iter().any(|row| row.id == row_id)
    }

    pub fn remove_row(&mut self, row_id: &str) {
        match self.rows.iter().position(|row| row.id == row_id) {
            None => {}
            Some(pos) => {
                self.rows.remove(pos);
            }
        }
    }

    pub fn add_row(&mut self, row_pb: RowPB) {
        match self.rows.iter().find(|row| row.id == row_pb.id) {
            None => {
                self.rows.push(row_pb);
            }
            Some(_) => {}
        }
    }
}

impl<C, T, G, P> GenericGroupController<C, T, G, P>
where
    C: TryFrom<Bytes, Error = protobuf::ProtobufError>,
    T: TypeOptionDataDeserializer,
    G: GroupGenerator<ConfigurationType = C, TypeOptionType = T>,
{
    pub fn new(field_rev: &Arc<FieldRevision>, configuration: GroupConfigurationRevision) -> FlowyResult<Self> {
        let configuration = match configuration.content {
            None => None,
            Some(content) => Some(C::try_from(Bytes::from(content))?),
        };
        let field_type_rev = field_rev.field_type_rev;
        let type_option = field_rev.get_type_option_entry::<T>(field_type_rev);
        let groups = G::generate_groups(&configuration, &type_option);

        let default_group = Group::new(
            DEFAULT_GROUP_ID.to_owned(),
            format!("No {}", field_rev.name),
            "".to_string(),
        );

        Ok(Self {
            field_id: field_rev.id.clone(),
            groups_map: groups.into_iter().map(|group| (group.id.clone(), group)).collect(),
            default_group,
            type_option,
            configuration,
            group_action_phantom: PhantomData,
            cell_parser_phantom: PhantomData,
        })
    }
}

impl<C, T, G, P> GroupControllerSharedAction for GenericGroupController<C, T, G, P>
where
    P: CellBytesParser,
    Self: Groupable<CellDataType = P::Object>,
{
    fn field_id(&self) -> &str {
        &self.field_id
    }

    fn build_groups(&self) -> Vec<Group> {
        let default_group = self.default_group.clone();
        let mut groups: Vec<Group> = self.groups_map.values().cloned().collect();
        if !default_group.rows.is_empty() {
            groups.push(default_group);
        }
        groups
    }

    fn group_rows(&mut self, row_revs: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
        if self.configuration.is_none() {
            return Ok(());
        }

        for row_rev in row_revs {
            if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
                let mut records: Vec<GroupRecord> = vec![];
                let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev);
                let cell_data = cell_bytes.parser::<P>()?;
                for group in self.groups_map.values() {
                    if self.can_group(&group.content, &cell_data) {
                        records.push(GroupRecord {
                            row: row_rev.into(),
                            group_id: group.id.clone(),
                        });
                    }
                }

                if records.is_empty() {
                    self.default_group.rows.push(row_rev.into());
                } else {
                    for record in records {
                        if let Some(group) = self.groups_map.get_mut(&record.group_id) {
                            group.rows.push(record.row);
                        }
                    }
                }
            } else {
                self.default_group.rows.push(row_rev.into());
            }
        }

        Ok(())
    }

    fn did_update_row(
        &mut self,
        row_rev: &RowRevision,
        field_rev: &FieldRevision,
    ) -> FlowyResult<Vec<GroupRowsChangesetPB>> {
        if let Some(cell_rev) = row_rev.cells.get(&self.field_id) {
            let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev);
            let cell_data = cell_bytes.parser::<P>()?;
            Ok(self.group_row(row_rev, &cell_data))
        } else {
            Ok(vec![])
        }
    }
}

// impl<C, T, G, P> GroupController<C, T, G, P>
// where
//     P: CellBytesParser,
//     Self: Groupable<CellDataType = P::Object>,
// {
//     pub fn handle_rows(&mut self, rows: &[Arc<RowRevision>], field_rev: &FieldRevision) -> FlowyResult<()> {
//         // The field_rev might be None if corresponding field_rev is deleted.
//         if self.configuration.is_none() {
//             return Ok(());
//         }
//
//         for row in rows {
//             if let Some(cell_rev) = row.cells.get(&self.field_id) {
//                 let mut records: Vec<GroupRecord> = vec![];
//                 let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), field_rev);
//                 let cell_data = cell_bytes.parser::<P>()?;
//                 for group in self.groups_map.values() {
//                     if self.can_group(&group.content, &cell_data) {
//                         records.push(GroupRecord {
//                             row: row.into(),
//                             group_id: group.id.clone(),
//                         });
//                     }
//                 }
//
//                 if records.is_empty() {
//                     self.default_group.rows.push(row.into());
//                 } else {
//                     for record in records {
//                         if let Some(group) = self.groups_map.get_mut(&record.group_id) {
//                             group.rows.push(record.row);
//                         }
//                     }
//                 }
//             } else {
//                 self.default_group.rows.push(row.into());
//             }
//         }
//
//         Ok(())
//     }
// }

struct GroupRecord {
    row: RowPB,
    group_id: String,
}
