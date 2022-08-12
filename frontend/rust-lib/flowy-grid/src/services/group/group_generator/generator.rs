use crate::services::cell::{decode_any_cell_data, CellBytes, CellBytesParser};
use bytes::Bytes;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{
    CellRevision, FieldRevision, GroupConfigurationRevision, RowRevision, TypeOptionDataDeserializer,
};
use std::collections::HashMap;
use std::marker::PhantomData;
use std::sync::Arc;

pub trait GroupAction<CD> {
    fn should_group(&self, content: &str, cell_data: CD) -> bool;
}

pub trait GroupCellContentProvider {
    /// We need to group the rows base on the deduplication cell content when the field type is
    /// RichText.
    fn deduplication_cell_content(&self, field_id: &str) -> Vec<String> {
        vec![]
    }
}

pub trait GroupGenerator<C, T> {
    fn gen_groups(
        configuration: &Option<C>,
        type_option: &Option<T>,
        cell_content_provider: &dyn GroupCellContentProvider,
    ) -> HashMap<String, Group>;
}

pub struct GroupController<C, T, G, CP> {
    field_rev: Arc<FieldRevision>,
    groups: HashMap<String, Group>,
    type_option: Option<T>,
    configuration: Option<C>,
    group_action_phantom: PhantomData<G>,
    cell_parser_phantom: PhantomData<CP>,
}

pub struct Group {
    row_ids: Vec<String>,
    content: String,
}

impl<C, T, G, CP> GroupController<C, T, G, CP>
where
    C: TryFrom<Bytes, Error = protobuf::ProtobufError>,
    T: TypeOptionDataDeserializer,
    G: GroupGenerator<C, T>,
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
        let field_type_rev = field_rev.field_type_rev.clone();
        let type_option = field_rev.get_type_option_entry::<T>(field_type_rev);
        Ok(Self {
            field_rev,
            groups: G::gen_groups(&configuration, &type_option, cell_content_provider),
            type_option,
            configuration,
            group_action_phantom: PhantomData,
            cell_parser_phantom: PhantomData,
        })
    }
}

impl<C, T, G, CP> GroupController<C, T, G, CP>
where
    CP: CellBytesParser,
    Self: GroupAction<CP::Object>,
{
    pub fn group_row(&mut self, row: &RowRevision) {
        if self.configuration.is_none() {
            return;
        }
        if let Some(cell_rev) = row.cells.get(&self.field_rev.id) {
            let mut group_row_id = None;
            let cell_bytes = decode_any_cell_data(cell_rev.data.clone(), &self.field_rev);
            // let cell_data = cell_bytes.with_parser(CP);
            for group in self.groups.values() {
                let cell_rev: CellRevision = cell_rev.clone();

                // if self.should_group(&group.content, cell_bytes) {
                //     group_row_id = Some(row.id.clone());
                //     break;
                // }
            }

            if let Some(group_row_id) = group_row_id {
                self.groups.get_mut(&group_row_id).map(|group| {
                    group.row_ids.push(group_row_id);
                });
            }
        }
    }
}
