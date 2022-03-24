use crate::services::field::type_options::*;
use flowy_grid_data_model::entities::{FieldMeta, FieldType};

pub struct FieldBuilder {
    field_meta: FieldMeta,
    type_option_builder: Box<dyn TypeOptionsBuilder>,
}

impl FieldBuilder {
    pub fn new<T: TypeOptionsBuilder + 'static>(type_option_builder: T) -> Self {
        let field_meta = FieldMeta::new("", "", type_option_builder.field_type());
        Self {
            field_meta,
            type_option_builder: Box::new(type_option_builder),
        }
    }

    pub fn from_field_type(field_type: &FieldType) -> Self {
        let type_option_builder = type_option_builder_from_type(field_type);
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

    pub fn build(mut self) -> FieldMeta {
        debug_assert_eq!(self.field_meta.field_type, self.type_option_builder.field_type());
        let type_options = self.type_option_builder.build();
        self.field_meta.type_option = type_options;
        self.field_meta
    }
}

pub trait TypeOptionsBuilder {
    fn field_type(&self) -> FieldType;
    fn build(&self) -> String;
}

pub fn type_option_builder_from_type(field_type: &FieldType) -> Box<dyn TypeOptionsBuilder> {
    match field_type {
        FieldType::RichText => Box::new(RichTextTypeOptionBuilder::default()),
        FieldType::Number => Box::new(NumberTypeOptionBuilder::default()),
        FieldType::DateTime => Box::new(DateTypeOptionBuilder::default()),
        FieldType::SingleSelect => Box::new(SingleSelectTypeOptionBuilder::default()),
        FieldType::MultiSelect => Box::new(MultiSelectTypeOptionBuilder::default()),
        FieldType::Checkbox => Box::new(CheckboxTypeOptionBuilder::default()),
    }
}

impl<T> TypeOptionsBuilder for Box<T>
where
    T: TypeOptionsBuilder + ?Sized,
{
    fn field_type(&self) -> FieldType {
        (**self).field_type()
    }

    fn build(&self) -> String {
        (**self).build()
    }
}
