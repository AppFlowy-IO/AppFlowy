use crate::entities::FieldType;
use crate::services::field::type_options::*;

use collab_database::fields::TypeOptionData;
use database_model::TypeOptionDataSerializer;

pub trait TypeOptionBuilder {
  /// Returns the type of the type-option data
  fn field_type(&self) -> FieldType;

  /// Returns a serializer that can be used to serialize the type-option data
  fn serializer(&self) -> &dyn TypeOptionDataSerializer;
}

pub fn default_type_option_data_from_type(field_type: &FieldType) -> TypeOptionData {
  match field_type {
    FieldType::RichText => RichTextTypeOption::default().into(),
    FieldType::Number => NumberTypeOption::default().into(),
    FieldType::DateTime => DateTypeOption::default().into(),
    FieldType::SingleSelect => SingleSelectTypeOption::default().into(),
    FieldType::MultiSelect => MultiSelectTypeOption::default().into(),
    FieldType::Checkbox => CheckboxTypeOption::default().into(),
    FieldType::URL => URLTypeOption::default().into(),
    FieldType::Checklist => ChecklistTypeOption::default().into(),
  }
}
