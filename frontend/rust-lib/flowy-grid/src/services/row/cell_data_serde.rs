use crate::services::field::*;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{FieldMeta, FieldType};

pub trait CellDataSerde {
    fn deserialize_cell_data(&self, data: String) -> String;
    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError>;
}

#[allow(dead_code)]
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
        FieldType::RichText => RichTextTypeOption::from(field_meta).deserialize_cell_data(data),
        FieldType::Number => NumberTypeOption::from(field_meta).deserialize_cell_data(data),
        FieldType::DateTime => DateTypeOption::from(field_meta).deserialize_cell_data(data),
        FieldType::SingleSelect => SingleSelectTypeOption::from(field_meta).deserialize_cell_data(data),
        FieldType::MultiSelect => MultiSelectTypeOption::from(field_meta).deserialize_cell_data(data),
        FieldType::Checkbox => CheckboxTypeOption::from(field_meta).deserialize_cell_data(data),
    };
    Ok(s)
}
