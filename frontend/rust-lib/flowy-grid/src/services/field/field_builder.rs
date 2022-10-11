use crate::entities::{FieldPB, FieldType};

use crate::services::field::{default_type_option_builder_from_type, TypeOptionBuilder};

use flowy_grid_data_model::revision::FieldRevision;
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
            ty: field.field_type.into(),
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
        field_rev.insert_type_option(self.type_option_builder.serializer());
        field_rev
    }
}
