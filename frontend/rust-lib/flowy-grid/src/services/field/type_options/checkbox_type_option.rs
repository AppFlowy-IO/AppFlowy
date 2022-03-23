use crate::impl_from_and_to_type_option;
use crate::services::field::TypeOptionsBuilder;
use crate::services::row::CellDataSerde;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{FieldMeta, FieldType};
use serde::{Deserialize, Serialize};

#[derive(Default)]
pub struct CheckboxTypeOptionsBuilder(CheckboxTypeOption);
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

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct CheckboxTypeOption {
    #[pb(index = 1)]
    pub is_selected: bool,
}
impl_from_and_to_type_option!(CheckboxTypeOption, FieldType::Checkbox);

impl CellDataSerde for CheckboxTypeOption {
    fn deserialize_cell_data(&self, data: String) -> String {
        data
    }

    fn serialize_cell_data(&self, data: &str) -> Result<String, FlowyError> {
        let s = match string_to_bool(data) {
            true => "1",
            false => "0",
        };
        Ok(s.to_owned())
    }
}

fn string_to_bool(bool_str: &str) -> bool {
    let lower_case_str: &str = &bool_str.to_lowercase();
    match lower_case_str {
        "1" => true,
        "true" => true,
        "yes" => true,
        "0" => false,
        "false" => false,
        "no" => false,
        _ => false,
    }
}

#[cfg(test)]
mod tests {
    use crate::services::cell::CheckboxTypeOption;
    use crate::services::row::CellDataSerde;

    #[test]
    fn checkout_box_description_test() {
        let description = CheckboxTypeOption::default();
        assert_eq!(description.serialize_cell_data("true").unwrap(), "1".to_owned());
        assert_eq!(description.serialize_cell_data("1").unwrap(), "1".to_owned());
        assert_eq!(description.serialize_cell_data("yes").unwrap(), "1".to_owned());

        assert_eq!(description.serialize_cell_data("false").unwrap(), "0".to_owned());
        assert_eq!(description.serialize_cell_data("no").unwrap(), "0".to_owned());
        assert_eq!(description.serialize_cell_data("123").unwrap(), "0".to_owned());

        assert_eq!(description.deserialize_cell_data("1".to_owned()), "1".to_owned());
    }
}
