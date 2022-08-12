use crate::entities::{FieldPB, FieldType};
use crate::services::field::type_options::*;
use bytes::Bytes;
use flowy_grid_data_model::revision::{FieldRevision, TypeOptionDataEntry};
use indexmap::IndexMap;

pub struct FieldBuilder {
    field_rev: FieldRevision,
    type_option_builder: Box<dyn TypeOptionBuilder>,
}

pub type BoxTypeOptionBuilder = Box<dyn TypeOptionBuilder + 'static>;

impl FieldBuilder {
    pub fn new<T: Into<BoxTypeOptionBuilder>>(type_option_builder: T) -> Self {
        let type_option_builder = type_option_builder.into();
        let field_type = type_option_builder.field_type();
        let width = field_type.default_cell_width();
        let field_rev = FieldRevision::new("", "", field_type, width, false);
        Self {
            field_rev,
            type_option_builder,
        }
    }

    pub fn from_field_type(field_type: &FieldType) -> Self {
        let type_option_builder = default_type_option_builder_from_type(field_type);
        Self::new(type_option_builder)
    }

    pub fn from_field(field: FieldPB, type_option_builder: Box<dyn TypeOptionBuilder>) -> Self {
        let field_rev = FieldRevision {
            id: field.id,
            name: field.name,
            desc: field.desc,
            field_type_rev: field.field_type.into(),
            frozen: field.frozen,
            visibility: field.visibility,
            width: field.width,
            type_options: IndexMap::default(),
            is_primary: field.is_primary,
        };
        Self {
            field_rev,
            type_option_builder,
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.field_rev.name = name.to_owned();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.field_rev.desc = desc.to_owned();
        self
    }

    pub fn primary(mut self, is_primary: bool) -> Self {
        self.field_rev.is_primary = is_primary;
        self
    }

    pub fn visibility(mut self, visibility: bool) -> Self {
        self.field_rev.visibility = visibility;
        self
    }

    pub fn width(mut self, width: i32) -> Self {
        self.field_rev.width = width;
        self
    }

    pub fn frozen(mut self, frozen: bool) -> Self {
        self.field_rev.frozen = frozen;
        self
    }

    pub fn build(self) -> FieldRevision {
        let mut field_rev = self.field_rev;
        field_rev.insert_type_option_entry(self.type_option_builder.entry());
        field_rev
    }
}

pub trait TypeOptionBuilder {
    fn field_type(&self) -> FieldType;
    fn entry(&self) -> &dyn TypeOptionDataEntry;
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
