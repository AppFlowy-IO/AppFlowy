use crate::entities::{CheckboxFilterPB, FieldType};
use crate::impl_type_option;
use crate::services::cell::{CellDataChangeset, CellDataDecoder, FromCellString, TypeCellData};
use crate::services::field::{
    default_order, BoxTypeOptionBuilder, CheckboxCellData, TypeOption, TypeOptionBuilder, TypeOptionCellData,
    TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionTransform,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
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
    type CellFilter = CheckboxFilterPB;
}

impl TypeOptionTransform for CheckboxTypeOptionPB {
    fn transformable(&self) -> bool {
        true
    }

    fn transform_type_option(&mut self, _old_type_option_field_type: FieldType, _old_type_option_data: String) {}

    fn transform_type_option_cell_str(
        &self,
        cell_str: &str,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> Option<<Self as TypeOption>::CellData> {
        if decoded_field_type.is_text() {
            match CheckboxCellData::from_str(&cell_str) {
                Ok(cell_data) => Some(cell_data),
                _flowy_error => None,
            }
        } else {
            None
        }
    }
}

impl TypeOptionCellData for CheckboxTypeOptionPB {
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType {
        cell_data
    }

    fn decode_type_option_cell_str(&self, cell_str: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        CheckboxCellData::from_cell_str(&cell_str)
    }
}

impl CellDataDecoder for CheckboxTypeOptionPB {
    fn decode_cell_str(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        if !decoded_field_type.is_checkbox() {
            return Ok(Default::default());
        }

        self.decode_type_option_cell_str(cell_str)
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
    ) -> FlowyResult<(String, <Self as TypeOption>::CellData)> {
        let checkbox_cell_data = CheckboxCellData::from_str(&changeset)?;
        Ok((checkbox_cell_data.to_string(), checkbox_cell_data))
    }
}

impl TypeOptionCellDataFilter for CheckboxTypeOptionPB {
    fn apply_filter(
        &self,
        filter: &<Self as TypeOption>::CellFilter,
        field_type: &FieldType,
        cell_data: &<Self as TypeOption>::CellData,
    ) -> bool {
        if !field_type.is_checkbox() {
            return true;
        }
        filter.is_visible(cell_data)
    }
}

impl TypeOptionCellDataCompare for CheckboxTypeOptionPB {
    fn apply_cmp(
        &self,
        cell_data: &<Self as TypeOption>::CellData,
        other_cell_data: &<Self as TypeOption>::CellData,
    ) -> Ordering {
        match (cell_data.is_check(), other_cell_data.is_check()) {
            (true, true) => Ordering::Equal,
            (true, false) => Ordering::Greater,
            (false, true) => Ordering::Less,
            (false, false) => default_order(),
        }
    }
}
