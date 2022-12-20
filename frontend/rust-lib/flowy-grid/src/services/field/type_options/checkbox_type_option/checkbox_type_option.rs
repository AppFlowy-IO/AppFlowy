use crate::entities::{CheckboxFilterPB, FieldType};
use crate::impl_type_option;
use crate::services::cell::{CellDataChangeset, CellDataDecoder, FromCellString, TypeCellData};
use crate::services::field::{
    BoxTypeOptionBuilder, CheckboxCellData, TypeOption, TypeOptionBuilder, TypeOptionCellData, TypeOptionConfiguration,
    TypeOptionTransform,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use serde::{Deserialize, Serialize};
use std::str::FromStr;

#[derive(Default)]
pub struct CheckboxTypeOptionBuilder(CheckboxTypeOptionPB);
impl_into_box_type_option_builder!(CheckboxTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(CheckboxTypeOptionBuilder, CheckboxTypeOptionPB);

impl CheckboxTypeOptionBuilder {
    pub fn set_selected(mut self, is_selected: bool) -> Self {
        self.0.is_selected = is_selected;
        self
    }
}

impl TypeOptionBuilder for CheckboxTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::Checkbox
    }

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct CheckboxTypeOptionPB {
    #[pb(index = 1)]
    pub is_selected: bool,
}
impl_type_option!(CheckboxTypeOptionPB, FieldType::Checkbox);

impl TypeOption for CheckboxTypeOptionPB {
    type CellData = CheckboxCellData;
    type CellChangeset = CheckboxCellChangeset;
    type CellProtobufType = CheckboxCellData;
}

impl TypeOptionTransform for CheckboxTypeOptionPB {}

impl TypeOptionConfiguration for CheckboxTypeOptionPB {
    type CellFilterConfiguration = CheckboxFilterPB;
}

impl TypeOptionCellData for CheckboxTypeOptionPB {
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType {
        cell_data
    }

    fn decode_type_option_cell_data(&self, cell_data: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        CheckboxCellData::from_cell_str(&cell_data)
    }
}

impl CellDataDecoder for CheckboxTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: String,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        if !decoded_field_type.is_checkbox() {
            return Ok(Default::default());
        }

        self.decode_type_option_cell_data(cell_data)
    }

    fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
        cell_data.to_string()
    }
}

pub type CheckboxCellChangeset = String;

impl CellDataChangeset for CheckboxTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: <Self as TypeOption>::CellChangeset,
        _type_cell_data: Option<TypeCellData>,
    ) -> FlowyResult<String> {
        let cell_data = CheckboxCellData::from_str(&changeset)?;
        Ok(cell_data.to_string())
    }
}
