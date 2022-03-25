use crate::services::field::type_options::*;
use bytes::Bytes;
use flowy_grid_data_model::entities::{FieldMeta, FieldType};

pub struct FieldBuilder {
    field_meta: FieldMeta,
    type_option_builder: Box<dyn TypeOptionBuilder>,
}

pub type BoxTypeOptionBuilder = Box<dyn TypeOptionBuilder + 'static>;

impl FieldBuilder {
    pub fn new<T: Into<BoxTypeOptionBuilder>>(type_option_builder: T) -> Self {
        let type_option_builder = type_option_builder.into();
        let field_meta = FieldMeta::new("", "", type_option_builder.field_type());
        Self {
            field_meta,
            type_option_builder,
        }
    }

    pub fn from_field_type(field_type: &FieldType) -> Self {
        let type_option_builder = default_type_option_builder_from_type(field_type);
        Self::new(type_option_builder)
    }

    pub fn name(mut self, name: &str) -> Self {
        self.field_meta.name = name.to_owned();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.field_meta.desc = desc.to_owned();
        self
    }

    pub fn visibility(mut self, visibility: bool) -> Self {
        self.field_meta.visibility = visibility;
        self
    }

    pub fn width(mut self, width: i32) -> Self {
        self.field_meta.width = width;
        self
    }

    pub fn frozen(mut self, frozen: bool) -> Self {
        self.field_meta.frozen = frozen;
        self
    }

    pub fn build(self) -> FieldMeta {
        debug_assert_eq!(self.field_meta.field_type, self.type_option_builder.field_type());
        let mut field_meta = self.field_meta;
        let type_option_json = self.type_option_builder.build_type_option_str();
        field_meta.type_option_json = type_option_json;
        field_meta
    }
}

pub trait TypeOptionBuilder {
    fn field_type(&self) -> FieldType;
    fn build_type_option_str(&self) -> String;
    fn build_type_option_data(&self) -> Bytes;
}

pub fn default_type_option_builder_from_type(field_type: &FieldType) -> Box<dyn TypeOptionBuilder> {
    let s: String = match field_type {
        FieldType::RichText => RichTextTypeOption::default().into(),
        FieldType::Number => NumberTypeOption::default().into(),
        FieldType::DateTime => DateTypeOption::default().into(),
        FieldType::SingleSelect => SingleSelectTypeOption::default().into(),
        FieldType::MultiSelect => MultiSelectTypeOption::default().into(),
        FieldType::Checkbox => CheckboxTypeOption::default().into(),
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
    }
}

pub fn type_option_builder_from_bytes(bytes: Bytes, field_type: &FieldType) -> Box<dyn TypeOptionBuilder> {
    match field_type {
        FieldType::RichText => Box::new(RichTextTypeOptionBuilder::from_bytes(bytes)),
        FieldType::Number => Box::new(NumberTypeOptionBuilder::from_bytes(bytes)),
        FieldType::DateTime => Box::new(DateTypeOptionBuilder::from_bytes(bytes)),
        FieldType::SingleSelect => Box::new(SingleSelectTypeOptionBuilder::from_bytes(bytes)),
        FieldType::MultiSelect => Box::new(MultiSelectTypeOptionBuilder::from_bytes(bytes)),
        FieldType::Checkbox => Box::new(CheckboxTypeOptionBuilder::from_bytes(bytes)),
    }
}

pub fn type_option_data_from_str(s: &str, field_type: &FieldType) -> Vec<u8> {
    let builder = type_option_builder_from_json_str(s, field_type);
    builder.build_type_option_data().to_vec()
}

pub fn type_option_json_str_from_bytes(bytes: Vec<u8>, field_type: &FieldType) -> String {
    let builder = type_option_builder_from_bytes(Bytes::from(bytes), field_type);
    builder.build_type_option_str()
}
