use crate::services::field::{
    CheckboxDescription, DateDescription, DateFormat, MoneySymbol, MultiSelectDescription, NumberDescription,
    RichTextDescription, SelectOption, SingleSelectDescription, TimeFormat,
};
use flowy_grid_data_model::entities::{AnyData, Field, FieldType};

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
    fn build(&self) -> AnyData;
}

// Text
pub struct RichTextTypeOptionsBuilder(RichTextDescription);

impl RichTextTypeOptionsBuilder {
    pub fn new() -> Self {
        Self(RichTextDescription::default())
    }
}

impl TypeOptionsBuilder for RichTextTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> AnyData {
        self.0.clone().into()
    }
}

// Number
pub struct NumberTypeOptionsBuilder(NumberDescription);

impl NumberTypeOptionsBuilder {
    pub fn new() -> Self {
        Self(NumberDescription::default())
    }

    pub fn name(mut self, name: &str) -> Self {
        self.0.name = name.to_string();
        self
    }

    pub fn set_money_symbol(mut self, money_symbol: MoneySymbol) -> Self {
        self.0.set_money_symbol(money_symbol);
        self
    }

    pub fn scale(mut self, scale: u32) -> Self {
        self.0.scale = scale;
        self
    }

    pub fn positive(mut self, positive: bool) -> Self {
        self.0.sign_positive = positive;
        self
    }
}

impl TypeOptionsBuilder for NumberTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> AnyData {
        self.0.clone().into()
    }
}

// Date
pub struct DateTypeOptionsBuilder(DateDescription);
impl DateTypeOptionsBuilder {
    pub fn new() -> Self {
        Self(DateDescription::default())
    }

    pub fn date_format(mut self, date_format: DateFormat) -> Self {
        self.0.date_format = date_format;
        self
    }

    pub fn time_format(mut self, time_format: TimeFormat) -> Self {
        self.0.time_format = time_format;
        self
    }
}
impl TypeOptionsBuilder for DateTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> AnyData {
        self.0.clone().into()
    }
}

// Single Select
pub struct SingleSelectTypeOptionsBuilder(SingleSelectDescription);

impl SingleSelectTypeOptionsBuilder {
    pub fn new() -> Self {
        Self(SingleSelectDescription::default())
    }

    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}
impl TypeOptionsBuilder for SingleSelectTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> AnyData {
        self.0.clone().into()
    }
}

// Multi Select
pub struct MultiSelectTypeOptionsBuilder(MultiSelectDescription);

impl MultiSelectTypeOptionsBuilder {
    pub fn new() -> Self {
        Self(MultiSelectDescription::default())
    }

    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionsBuilder for MultiSelectTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> AnyData {
        self.0.clone().into()
    }
}

// Checkbox
pub struct CheckboxTypeOptionsBuilder(CheckboxDescription);
impl CheckboxTypeOptionsBuilder {
    pub fn new() -> Self {
        Self(CheckboxDescription::default())
    }

    pub fn set_selected(mut self, is_selected: bool) -> Self {
        self.0.is_selected = is_selected;
        self
    }
}
impl TypeOptionsBuilder for CheckboxTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> AnyData {
        self.0.clone().into()
    }
}
