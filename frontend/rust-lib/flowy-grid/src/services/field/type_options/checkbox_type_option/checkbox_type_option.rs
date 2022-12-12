use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{
    AnyCellChangeset, CellBytes, CellComparable, CellDataOperation, CellDataSerialize, IntoCellData, TypeCellData,
};
use crate::services::field::{BoxTypeOptionBuilder, CheckboxCellData, TypeOptionBuilder};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
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

    fn transform(&mut self, _field_type: &FieldType, _type_option_data: String) {
        // Do nothing
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct CheckboxTypeOptionPB {
    #[pb(index = 1)]
    pub is_selected: bool,
}
impl_type_option!(CheckboxTypeOptionPB, FieldType::Checkbox);

impl CellDataSerialize<CheckboxCellData> for CheckboxTypeOptionPB {
    fn serialize_cell_data_to_bytes(
        &self,
        cell_data: IntoCellData<CheckboxCellData>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_data = cell_data.try_into_inner()?;
        Ok(CellBytes::new(cell_data))
    }

    fn serialize_cell_data_to_str(
        &self,
        cell_data: IntoCellData<CheckboxCellData>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<String> {
        let cell_data = cell_data.try_into_inner()?;
        Ok(cell_data.to_string())
    }
}

pub type CheckboxCellChangeset = String;

impl CellDataOperation<CheckboxCellData, CheckboxCellChangeset> for CheckboxTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: IntoCellData<CheckboxCellData>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if !decoded_field_type.is_checkbox() {
            return Ok(CellBytes::default());
        }

        self.serialize_cell_data_to_bytes(cell_data, decoded_field_type, field_rev)
    }

    fn apply_changeset(
        &self,
        changeset: AnyCellChangeset<String>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.try_into_inner()?;
        let cell_data = CheckboxCellData::from_str(&changeset)?;
        Ok(cell_data.to_string())
    }
}

impl CellComparable for CheckboxTypeOptionPB {
    fn apply_cmp(&self, type_cell_data: &TypeCellData, other_type_cell_data: &TypeCellData) -> Ordering {
        Ordering::Equal
    }
}
