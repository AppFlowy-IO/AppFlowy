use crate::entities::FieldType;
use crate::services::field::type_options::*;
use bytes::Bytes;
use flowy_grid_data_model::revision::TypeOptionDataSerializer;

pub trait TypeOptionBuilder {
    fn field_type(&self) -> FieldType;
    fn serializer(&self) -> &dyn TypeOptionDataSerializer;

    /// Transform the data from passed-in type-option to current type-option
    ///
    /// # Arguments
    ///
    /// * `field_type`: represents as the field type of the passed-in type-option data
    /// * `type_option_data`: type-option data
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
    }
}
