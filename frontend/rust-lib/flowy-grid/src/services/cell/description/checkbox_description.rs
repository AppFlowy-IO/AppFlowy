use crate::impl_from_and_to_type_option;
use crate::services::row::StringifyCellData;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{Field, FieldType};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct CheckboxDescription {
    #[pb(index = 1)]
    pub is_selected: bool,
}
impl_from_and_to_type_option!(CheckboxDescription, FieldType::Checkbox);

impl StringifyCellData for CheckboxDescription {
    fn str_from_cell_data(&self, data: String) -> String {
        data
    }

    fn str_to_cell_data(&self, s: &str) -> Result<String, FlowyError> {
        let s = match string_to_bool(s) {
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
    use crate::services::cell::CheckboxDescription;
    use crate::services::row::StringifyCellData;

    #[test]
    fn checkout_box_description_test() {
        let description = CheckboxDescription::default();
        assert_eq!(description.str_to_cell_data("true").unwrap(), "1".to_owned());
        assert_eq!(description.str_to_cell_data("1").unwrap(), "1".to_owned());
        assert_eq!(description.str_to_cell_data("yes").unwrap(), "1".to_owned());

        assert_eq!(description.str_to_cell_data("false").unwrap(), "0".to_owned());
        assert_eq!(description.str_to_cell_data("no").unwrap(), "0".to_owned());
        assert_eq!(description.str_to_cell_data("123").unwrap(), "0".to_owned());

        assert_eq!(description.str_from_cell_data("1".to_owned()), "1".to_owned());
    }
}
