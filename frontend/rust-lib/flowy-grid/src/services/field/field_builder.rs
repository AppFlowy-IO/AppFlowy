use flowy_grid_data_model::entities::{FieldMeta, FieldType};

pub struct FieldBuilder {
    field_meta: FieldMeta,
    type_options_builder: Box<dyn TypeOptionsBuilder>,
}

impl FieldBuilder {
    pub fn new<T: TypeOptionsBuilder + 'static>(type_options_builder: T) -> Self {
        let field_meta = FieldMeta::new("Name", "", FieldType::RichText);
        Self {
            field_meta,
            type_options_builder: Box::new(type_options_builder),
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.field_meta.name = name.to_owned();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.field_meta.desc = desc.to_owned();
        self
    }

    pub fn field_type(mut self, field_type: FieldType) -> Self {
        self.field_meta.field_type = field_type;
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
        assert_eq!(self.field_meta.field_type, self.type_options_builder.field_type());

        let type_options = self.type_options_builder.build();
        self.field_meta.type_options = type_options;
        self.field_meta
    }
}

pub trait TypeOptionsBuilder {
    fn field_type(&self) -> FieldType;
    fn build(&self) -> String;
}
