use crate::services::cell_data::*;
use crate::services::util::*;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{AnyData, Field, FieldType};

pub trait AnyDataSerde {
    fn serialize(field: &Field, s: &str) -> Result<AnyData, FlowyError> {
        match field.field_type {
            FieldType::RichText => RichTextDescription::from(field).str_to_any_data(s),
            FieldType::Number => NumberDescription::from(field).str_to_any_data(s),
            FieldType::DateTime => DateDescription::from(field).str_to_any_data(s),
            FieldType::SingleSelect => SingleSelect::from(field).str_to_any_data(s),
            FieldType::MultiSelect => MultiSelect::from(field).str_to_any_data(s),
            FieldType::Checkbox => CheckboxDescription::from(field).str_to_any_data(s),
        }
    }

    fn deserialize(data: &AnyData, field: &Field) -> Result<String, FlowyError> {
        let _ = check_type_id(data, field)?;
        let s = match field.field_type {
            FieldType::RichText => RichTextDescription::from(field).stringify_any_data(data),
            FieldType::Number => NumberDescription::from(field).stringify_any_data(data),
            FieldType::DateTime => DateDescription::from(field).stringify_any_data(data),
            FieldType::SingleSelect => SingleSelect::from(field).stringify_any_data(data),
            FieldType::MultiSelect => MultiSelect::from(field).stringify_any_data(data),
            FieldType::Checkbox => CheckboxDescription::from(field).stringify_any_data(data),
        };
        Ok(s)
    }
}
