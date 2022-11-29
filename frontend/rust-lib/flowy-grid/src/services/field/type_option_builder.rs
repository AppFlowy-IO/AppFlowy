use crate::entities::FieldType;
use crate::services::field::type_options::*;
use bytes::Bytes;
use grid_rev_model::TypeOptionDataSerializer;

pub trait TypeOptionBuilder {
    /// Returns the type of the type-option data
    fn field_type(&self) -> FieldType;

    /// Returns a serializer that can be used to serialize the type-option data
    fn serializer(&self) -> &dyn TypeOptionDataSerializer;

    /// Transform the data from passed-in type-option to current type-option
    ///
    /// The current type-option data may be changed if it supports transform
    /// the data from the other kind of type-option data.
    ///
    /// For example, when switching from `checkbox` type-option to `single-select`
    /// type-option, adding the `Yes` option if the `single-select` type-option doesn't contain it.
    /// But the cell content is a string, `Yes`, it's need to do the cell content transform.
    /// The `Yes` string will be transformed to the `Yes` option id.
    ///
    ///
    /// # Arguments
    ///
    /// * `field_type`: represents as the field type of the passed-in type-option data
    /// * `type_option_data`: passed-in type-option data
    //
    fn transform(&mut self, field_type: &FieldType, type_option_data: String);
}

pub fn default_type_option_builder_from_type(field_type: &FieldType) -> Box<dyn TypeOptionBuilder> {
    let s: String = match field_type {
        FieldType::RichText => RichTextTypeOptionPB::default().into(),
        FieldType::Number => NumberTypeOptionPB::default().into(),
        FieldType::DateTime => DateTypeOptionPB::default().into(),
        FieldType::SingleSelect => SingleSelectTypeOptionPB::default().into(),
        FieldType::MultiSelect => MultiSelectTypeOptionPB::default().into(),
        FieldType::Checkbox => CheckboxTypeOptionPB::default().into(),
        FieldType::URL => URLTypeOptionPB::default().into(),
        FieldType::Checklist => ChecklistTypeOptionPB::default().into(),
    };

    type_option_builder_from_json_str(&s, field_type)
}

pub fn type_option_builder_from_json_str(s: &str, field_type: &FieldType) -> Box<dyn TypeOptionBuilder> {
    match field_type {
        FieldType::RichText => Box::new(RichTextTypeOptionBuilder::from_json_str(s)),
        FieldType::Number => Box::new(NumberTypeOptionBuilder::from_json_str(s)),
        FieldType::DateTime => Box::new(DateTypeOptionBuilder::from_json_str(s)),
        FieldType::SingleSelect => Box::new(SingleSelectTypeOptionBuilder::from_json_str(s)),
        FieldType::MultiSelect => Box::new(MultiSelectTypeOptionBuilder::from_json_str(s)),
        FieldType::Checkbox => Box::new(CheckboxTypeOptionBuilder::from_json_str(s)),
        FieldType::URL => Box::new(URLTypeOptionBuilder::from_json_str(s)),
        FieldType::Checklist => Box::new(ChecklistTypeOptionBuilder::from_json_str(s)),
    }
}

pub fn type_option_builder_from_bytes<T: Into<Bytes>>(bytes: T, field_type: &FieldType) -> Box<dyn TypeOptionBuilder> {
    let bytes = bytes.into();
    match field_type {
        FieldType::RichText => Box::new(RichTextTypeOptionBuilder::from_protobuf_bytes(bytes)),
        FieldType::Number => Box::new(NumberTypeOptionBuilder::from_protobuf_bytes(bytes)),
        FieldType::DateTime => Box::new(DateTypeOptionBuilder::from_protobuf_bytes(bytes)),
        FieldType::SingleSelect => Box::new(SingleSelectTypeOptionBuilder::from_protobuf_bytes(bytes)),
        FieldType::MultiSelect => Box::new(MultiSelectTypeOptionBuilder::from_protobuf_bytes(bytes)),
        FieldType::Checkbox => Box::new(CheckboxTypeOptionBuilder::from_protobuf_bytes(bytes)),
        FieldType::URL => Box::new(URLTypeOptionBuilder::from_protobuf_bytes(bytes)),
        FieldType::Checklist => Box::new(ChecklistTypeOptionBuilder::from_protobuf_bytes(bytes)),
    }
}
