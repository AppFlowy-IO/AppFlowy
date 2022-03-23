use crate::services::field::*;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{FieldMeta, FieldType};

pub trait CellDataSerde {
    fn deserialize_cell_data(&self, data: String) -> String;
    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError>;
}

#[allow(dead_code)]
pub fn serialize_cell_data(data: &str, field: &FieldMeta) -> Result<String, FlowyError> {
    match field.field_type {
        FieldType::RichText => RichTextTypeOption::from(field).serialize_cell_data(data),
        FieldType::Number => NumberTypeOption::from(field).serialize_cell_data(data),
        FieldType::DateTime => DateTypeOption::from(field).serialize_cell_data(data),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field).serialize_cell_data(data),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field).serialize_cell_data(data),
        FieldType::Checkbox => CheckboxTypeOption::from(field).serialize_cell_data(data),
    }
}

pub fn deserialize_cell_data(data: String, field: &FieldMeta) -> Result<String, FlowyError> {
    let s = match field.field_type {
        FieldType::RichText => RichTextTypeOption::from(field).deserialize_cell_data(data),
        FieldType::Number => NumberTypeOption::from(field).deserialize_cell_data(data),
        FieldType::DateTime => DateTypeOption::from(field).deserialize_cell_data(data),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field).deserialize_cell_data(data),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field).deserialize_cell_data(data),
        FieldType::Checkbox => CheckboxTypeOption::from(field).deserialize_cell_data(data),
    };
    Ok(s)
}
