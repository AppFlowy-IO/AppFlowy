use flowy_grid_data_model::entities::{Field, FieldType};

pub struct FieldBuilder {
    field: Field,
    type_options_builder: Box<dyn TypeOptionsBuilder>,
}

impl FieldBuilder {
    pub fn new<T: TypeOptionsBuilder + 'static>(type_options_builder: T) -> Self {
        let field = Field::new("Name", "", FieldType::RichText);
        Self {
            field,
            type_options_builder: Box::new(type_options_builder),
        }
    }

    pub fn name(mut self, name: &str) -> Self {
        self.field.name = name.to_owned();
        self
    }

    pub fn desc(mut self, desc: &str) -> Self {
        self.field.desc = desc.to_owned();
        self
    }

    pub fn field_type(mut self, field_type: FieldType) -> Self {
        self.field.field_type = field_type;
        self
    }

    pub fn visibility(mut self, visibility: bool) -> Self {
        self.field.visibility = visibility;
        self
    }

    pub fn width(mut self, width: i32) -> Self {
        self.field.width = width;
        self
    }

    pub fn frozen(mut self, frozen: bool) -> Self {
        self.field.frozen = frozen;
        self
    }

    pub fn build(mut self) -> Field {
        assert_eq!(self.field.field_type, self.type_options_builder.field_type());

        let type_options = self.type_options_builder.build();
        self.field.type_options = type_options;
        self.field
    }
}

pub trait TypeOptionsBuilder {
    fn field_type(&self) -> FieldType;
    fn build(&self) -> String;
}
