use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellContentChangeset, CellDataOperation, DecodedCellData, TypeOptionCellData};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};

use serde::{Deserialize, Serialize};
use std::str::FromStr;

#[derive(Default)]
pub struct CheckboxTypeOptionBuilder(CheckboxTypeOption);
impl_into_box_type_option_builder!(CheckboxTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(CheckboxTypeOptionBuilder, CheckboxTypeOption);

impl CheckboxTypeOptionBuilder {
    pub fn set_selected(mut self, is_selected: bool) -> Self {
        self.0.is_selected = is_selected;
        self
    }
}

impl TypeOptionBuilder for CheckboxTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct CheckboxTypeOption {
    #[pb(index = 1)]
    pub is_selected: bool,
}
impl_type_option!(CheckboxTypeOption, FieldType::Checkbox);

const YES: &str = "Yes";
const NO: &str = "No";

impl CellDataOperation for CheckboxTypeOption {
    fn decode_cell_data(&self, data: String, _field_meta: &FieldMeta) -> DecodedCellData {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if !type_option_cell_data.is_checkbox() {
                return DecodedCellData::default();
            }
            let cell_data = type_option_cell_data.data;
            if cell_data == YES || cell_data == NO {
                return DecodedCellData::from_content(cell_data);
            }
        }

        DecodedCellData::default()
    }

    fn apply_changeset<T: Into<CellContentChangeset>>(
        &self,
        changeset: T,
        _cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.into();
        let s = match string_to_bool(&changeset) {
            true => YES,
            false => NO,
        };
        Ok(TypeOptionCellData::new(s, self.field_type()).json())
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
    use crate::services::field::type_options::checkbox_type_option::{NO, YES};
    use crate::services::field::CheckboxTypeOption;
    use crate::services::field::FieldBuilder;
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::entities::FieldType;

    #[test]
    fn checkout_box_description_test() {
        let type_option = CheckboxTypeOption::default();
        let field_meta = FieldBuilder::from_field_type(&FieldType::DateTime).build();

        let data = type_option.apply_changeset("true", None).unwrap();
        assert_eq!(type_option.decode_cell_data(data, &field_meta).content, YES);

        let data = type_option.apply_changeset("1", None).unwrap();
        assert_eq!(type_option.decode_cell_data(data, &field_meta).content, YES);

        let data = type_option.apply_changeset("yes", None).unwrap();
        assert_eq!(type_option.decode_cell_data(data, &field_meta).content, YES);

        let data = type_option.apply_changeset("false", None).unwrap();
        assert_eq!(type_option.decode_cell_data(data, &field_meta).content, NO);

        let data = type_option.apply_changeset("no", None).unwrap();
        assert_eq!(type_option.decode_cell_data(data, &field_meta).content, NO);

        let data = type_option.apply_changeset("123", None).unwrap();
        assert_eq!(type_option.decode_cell_data(data, &field_meta).content, NO);
    }
}
