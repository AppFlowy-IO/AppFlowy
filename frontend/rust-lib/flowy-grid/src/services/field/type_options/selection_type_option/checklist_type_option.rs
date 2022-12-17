use crate::entities::{ChecklistFilterPB, FieldType};
use crate::impl_type_option;
use crate::services::cell::{AnyCellChangeset, CellDataChangeset, FromCellString, TypeCellData};
use crate::services::field::selection_type_option::type_option_transform::SelectOptionTypeOptionTransformer;
use crate::services::field::{
    BoxTypeOptionBuilder, SelectOptionCellChangeset, SelectOptionCellDataPB, SelectOptionIds, SelectOptionPB,
    SelectTypeOptionSharedAction, TypeOption, TypeOptionBuilder, TypeOptionCellData, TypeOptionConfiguration,
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

impl TypeOption for ChecklistTypeOptionPB {
    type CellData = SelectOptionIds;
    type CellChangeset = SelectOptionCellChangeset;
    type CellPBType = SelectOptionCellDataPB;
}

impl TypeOptionConfiguration for ChecklistTypeOptionPB {
    type CellFilterConfiguration = ChecklistFilterPB;
}

impl TypeOptionCellData for ChecklistTypeOptionPB {
    fn convert_into_pb_type(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellPBType {
        self.get_selected_options(cell_data)
    }

    fn decode_type_option_cell_data(&self, cell_data: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        SelectOptionIds::from_cell_str(&cell_data)
    }
}

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

impl CellDataChangeset for ChecklistTypeOptionPB {
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
                let cell_data = TypeCellData::try_from(cell_rev)
                    .map(|data| data.into_inner())
                    .unwrap_or_default();
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
