use crate::services::cell::*;
use crate::services::field::TypeOptionsBuilder;
use flowy_grid_data_model::entities::FieldType;

// Text
#[derive(Default)]
pub struct RichTextTypeOptionsBuilder(RichTextDescription);

impl TypeOptionsBuilder for RichTextTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> String {
        self.0.clone().into()
    }
}

// Number
#[derive(Default)]
pub struct NumberTypeOptionsBuilder(NumberDescription);

impl NumberTypeOptionsBuilder {
    pub fn name(mut self, name: &str) -> Self {
        self.0.name = name.to_string();
        self
    }

    pub fn set_format(mut self, format: NumberFormat) -> Self {
        self.0.set_format(format);
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

    fn build(&self) -> String {
        self.0.clone().into()
    }
}

// Date
#[derive(Default)]
pub struct DateTypeOptionsBuilder(DateDescription);
impl DateTypeOptionsBuilder {
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

    fn build(&self) -> String {
        self.0.clone().into()
    }
}

// Single Select
#[derive(Default)]
pub struct SingleSelectTypeOptionsBuilder(SingleSelectDescription);

impl SingleSelectTypeOptionsBuilder {
    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}
impl TypeOptionsBuilder for SingleSelectTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> String {
        self.0.clone().into()
    }
}

// Multi Select
#[derive(Default)]
pub struct MultiSelectTypeOptionsBuilder(MultiSelectDescription);

impl MultiSelectTypeOptionsBuilder {
    pub fn option(mut self, opt: SelectOption) -> Self {
        self.0.options.push(opt);
        self
    }
}

impl TypeOptionsBuilder for MultiSelectTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> String {
        self.0.clone().into()
    }
}

// Checkbox
#[derive(Default)]
pub struct CheckboxTypeOptionsBuilder(CheckboxDescription);
impl CheckboxTypeOptionsBuilder {
    pub fn set_selected(mut self, is_selected: bool) -> Self {
        self.0.is_selected = is_selected;
        self
    }
}
impl TypeOptionsBuilder for CheckboxTypeOptionsBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn build(&self) -> String {
        self.0.clone().into()
    }
}
