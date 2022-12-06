use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{AnyCellChangeset, CellBytes, CellData, CellDataOperation, CellDisplayable};
use crate::services::field::selection_type_option::type_option_transform::SelectOptionTypeOptionTransformer;
use crate::services::field::type_options::util::get_cell_data;
use crate::services::field::{
    BoxTypeOptionBuilder, SelectOptionCellChangeset, SelectOptionIds, SelectOptionPB, SelectTypeOptionSharedAction,
    TypeOptionBuilder,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use serde::{Deserialize, Serialize};

// Multiple select
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct ChecklistTypeOptionPB {
    #[pb(index = 1)]
    pub options: Vec<SelectOptionPB>,

    #[pb(index = 2)]
    pub disable_color: bool,
}
impl_type_option!(ChecklistTypeOptionPB, FieldType::Checklist);

impl SelectTypeOptionSharedAction for ChecklistTypeOptionPB {
    fn number_of_max_options(&self) -> Option<usize> {
        None
    }

    fn options(&self) -> &Vec<SelectOptionPB> {
        &self.options
    }

    fn mut_options(&mut self) -> &mut Vec<SelectOptionPB> {
        &mut self.options
    }
}

impl CellDataOperation<SelectOptionIds, SelectOptionCellChangeset> for ChecklistTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: CellData<SelectOptionIds>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        self.displayed_cell_bytes(cell_data, decoded_field_type, field_rev)
    }

    fn apply_changeset(
        &self,
        changeset: AnyCellChangeset<SelectOptionCellChangeset>,
        cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let content_changeset = changeset.try_into_inner()?;

        let insert_option_ids = content_changeset
            .insert_option_ids
            .into_iter()
            .filter(|insert_option_id| self.options.iter().any(|option| &option.id == insert_option_id))
            .collect::<Vec<String>>();

        match cell_rev {
            None => Ok(SelectOptionIds::from(insert_option_ids).to_string()),
            Some(cell_rev) => {
                let cell_data = get_cell_data(&cell_rev);
                let mut select_ids: SelectOptionIds = cell_data.into();
                for insert_option_id in insert_option_ids {
                    if !select_ids.contains(&insert_option_id) {
                        select_ids.push(insert_option_id);
                    }
                }

                for delete_option_id in content_changeset.delete_option_ids {
                    select_ids.retain(|id| id != &delete_option_id);
                }

                Ok(select_ids.to_string())
            }
        }
    }
}

#[derive(Default)]
pub struct ChecklistTypeOptionBuilder(ChecklistTypeOptionPB);
impl_into_box_type_option_builder!(ChecklistTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(ChecklistTypeOptionBuilder, ChecklistTypeOptionPB);
impl ChecklistTypeOptionBuilder {
    pub fn add_option(mut self, opt: SelectOptionPB) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionBuilder for ChecklistTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::Checklist
    }

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }

    fn transform(&mut self, field_type: &FieldType, type_option_data: String) {
        SelectOptionTypeOptionTransformer::transform_type_option(&mut self.0, field_type, type_option_data)
    }
}
