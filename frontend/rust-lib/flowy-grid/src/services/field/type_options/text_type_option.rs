use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{decode_cell_data, CellDataChangeset, CellDataOperation, TypeOptionCellData};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{CellMeta, FieldMeta, FieldType, TypeOptionDataEntity, TypeOptionDataEntry};
use serde::{Deserialize, Serialize};
use std::str::FromStr;

#[derive(Default)]
pub struct RichTextTypeOptionBuilder(RichTextTypeOption);
impl_into_box_type_option_builder!(RichTextTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(RichTextTypeOptionBuilder, RichTextTypeOption);

impl TypeOptionBuilder for RichTextTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize, ProtoBuf)]
pub struct RichTextTypeOption {
    #[pb(index = 1)]
    pub format: String,
}
impl_type_option!(RichTextTypeOption, FieldType::RichText);

impl CellDataOperation for RichTextTypeOption {
    fn decode_cell_data(&self, data: String, field_meta: &FieldMeta) -> String {
        if let Ok(type_option_cell_data) = TypeOptionCellData::from_str(&data) {
            if type_option_cell_data.is_date()
                || type_option_cell_data.is_single_select()
                || type_option_cell_data.is_multi_select()
                || type_option_cell_data.is_number()
            {
                decode_cell_data(data, field_meta).unwrap_or_else(|_| "".to_owned())
            } else {
                type_option_cell_data.data
            }
        } else {
            String::new()
        }
    }

    fn apply_changeset<T: Into<CellDataChangeset>>(
        &self,
        changeset: T,
        _cell_meta: Option<CellMeta>,
    ) -> Result<String, FlowyError> {
        let data = changeset.into();
        if data.len() > 10000 {
            Err(FlowyError::text_too_long().context("The len of the text should not be more than 10000"))
        } else {
            Ok(TypeOptionCellData::new(&data, self.field_type()).json())
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::services::field::FieldBuilder;
    use crate::services::field::*;
    use crate::services::row::{CellDataOperation, TypeOptionCellData};
    use flowy_grid_data_model::entities::FieldType;

    #[test]
    fn text_description_test() {
        let type_option = RichTextTypeOption::default();

        // date
        let date_time_field_meta = FieldBuilder::from_field_type(&FieldType::DateTime).build();
        let data = TypeOptionCellData::new("1647251762", FieldType::DateTime).json();
        assert_eq!(
            type_option.decode_cell_data(data, &date_time_field_meta),
            "Mar 14,2022 17:56".to_owned()
        );

        // Single select
        let done_option = SelectOption::new("Done");
        let done_option_id = done_option.id.clone();
        let single_select = SingleSelectTypeOptionBuilder::default().option(done_option);
        let single_select_field_meta = FieldBuilder::new(single_select).build();
        let cell_data = TypeOptionCellData::new(&done_option_id, FieldType::SingleSelect).json();
        assert_eq!(
            type_option.decode_cell_data(cell_data, &single_select_field_meta),
            "Done".to_owned()
        );

        // Multiple select
        let google_option = SelectOption::new("Google");
        let facebook_option = SelectOption::new("Facebook");
        let ids = vec![google_option.id.clone(), facebook_option.id.clone()].join(SELECTION_IDS_SEPARATOR);
        let cell_data_changeset = SelectOptionCellChangeset::from_insert(&ids).cell_data();
        let multi_select = MultiSelectTypeOptionBuilder::default()
            .option(google_option)
            .option(facebook_option);
        let multi_select_field_meta = FieldBuilder::new(multi_select).build();
        let multi_type_option = MultiSelectTypeOption::from(&multi_select_field_meta);
        let cell_data = multi_type_option.apply_changeset(cell_data_changeset, None).unwrap();
        assert_eq!(
            type_option.decode_cell_data(cell_data, &multi_select_field_meta),
            "Google,Facebook".to_owned()
        );

        //Number
        let number = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
        let number_field_meta = FieldBuilder::new(number).build();
        let data = TypeOptionCellData::new("18443", FieldType::Number).json();
        assert_eq!(
            type_option.decode_cell_data(data, &number_field_meta),
            "$18,443".to_owned()
        );
    }
}
