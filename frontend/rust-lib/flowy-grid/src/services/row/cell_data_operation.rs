use crate::services::field::*;
use bytes::Bytes;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{FieldMeta, FieldType};
use serde::{Deserialize, Serialize};

pub trait CellDataOperation {
    fn deserialize_cell_data(&self, data: String, field_meta: &FieldMeta) -> String;
    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError>;
    // fn apply_changeset()
}

#[derive(Serialize, Deserialize)]
pub struct TypeOptionCellData {
    pub data: String,
    pub field_type: FieldType,
}

impl std::str::FromStr for TypeOptionCellData {
    type Err = FlowyError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let type_option_cell_data: TypeOptionCellData = serde_json::from_str(s)?;
        Ok(type_option_cell_data)
    }
}

impl TypeOptionCellData {
    pub fn new(data: &str, field_type: FieldType) -> Self {
        TypeOptionCellData {
            data: data.to_owned(),
            field_type,
        }
    }

    pub fn json(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|_| "".to_owned())
    }

    pub fn is_number(&self) -> bool {
        self.field_type == FieldType::Number
    }

    pub fn is_text(&self) -> bool {
        self.field_type == FieldType::RichText
    }

    pub fn is_checkbox(&self) -> bool {
        self.field_type == FieldType::Checkbox
    }

    pub fn is_date(&self) -> bool {
        self.field_type == FieldType::DateTime
    }

    pub fn is_single_select(&self) -> bool {
        self.field_type == FieldType::SingleSelect
    }

    pub fn is_multi_select(&self) -> bool {
        self.field_type == FieldType::MultiSelect
    }
}

pub fn serialize_cell_data(data: &str, field_meta: &FieldMeta) -> Result<String, FlowyError> {
    match field_meta.field_type {
        FieldType::RichText => RichTextTypeOption::from(field_meta).serialize_cell_data(data),
        FieldType::Number => NumberTypeOption::from(field_meta).serialize_cell_data(data),
        FieldType::DateTime => DateTypeOption::from(field_meta).serialize_cell_data(data),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field_meta).serialize_cell_data(data),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field_meta).serialize_cell_data(data),
        FieldType::Checkbox => CheckboxTypeOption::from(field_meta).serialize_cell_data(data),
    }
}

pub fn deserialize_cell_data(data: String, field_meta: &FieldMeta) -> Result<String, FlowyError> {
    let s = match field_meta.field_type {
        FieldType::RichText => RichTextTypeOption::from(field_meta).deserialize_cell_data(data, field_meta),
        FieldType::Number => NumberTypeOption::from(field_meta).deserialize_cell_data(data, field_meta),
        FieldType::DateTime => DateTypeOption::from(field_meta).deserialize_cell_data(data, field_meta),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field_meta).deserialize_cell_data(data, field_meta),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field_meta).deserialize_cell_data(data, field_meta),
        FieldType::Checkbox => CheckboxTypeOption::from(field_meta).deserialize_cell_data(data, field_meta),
    };
    Ok(s)
}
