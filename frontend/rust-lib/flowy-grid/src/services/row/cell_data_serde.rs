use crate::services::cell::*;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{FieldMeta, FieldType};

pub trait CellDataSerde {
    fn deserialize_cell_data(&self, data: String) -> String;
    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError>;
}

#[allow(dead_code)]
pub fn serialize_cell_data(data: &str, field: &FieldMeta) -> Result<String, FlowyError> {
    match field.field_type {
        FieldType::RichText => RichTextDescription::from(field).serialize_cell_data(data),
        FieldType::Number => NumberDescription::from(field).serialize_cell_data(data),
        FieldType::DateTime => DateDescription::from(field).serialize_cell_data(data),
        FieldType::SingleSelect => SingleSelectDescription::from(field).serialize_cell_data(data),
        FieldType::MultiSelect => MultiSelectDescription::from(field).serialize_cell_data(data),
        FieldType::Checkbox => CheckboxDescription::from(field).serialize_cell_data(data),
    }
}

pub fn deserialize_cell_data(data: String, field: &FieldMeta) -> Result<String, FlowyError> {
    let s = match field.field_type {
        FieldType::RichText => RichTextDescription::from(field).deserialize_cell_data(data),
        FieldType::Number => NumberDescription::from(field).deserialize_cell_data(data),
        FieldType::DateTime => DateDescription::from(field).deserialize_cell_data(data),
        FieldType::SingleSelect => SingleSelectDescription::from(field).deserialize_cell_data(data),
        FieldType::MultiSelect => MultiSelectDescription::from(field).deserialize_cell_data(data),
        FieldType::Checkbox => CheckboxDescription::from(field).deserialize_cell_data(data),
    };
    Ok(s)
}
