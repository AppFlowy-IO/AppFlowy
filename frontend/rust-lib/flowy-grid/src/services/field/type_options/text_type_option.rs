use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{
    decode_cell_data, CellContentChangeset, CellDataOperation, DecodedCellData, TypeOptionCellData,
};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyError;
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
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

impl CellDataOperation<String> for RichTextTypeOption {
    fn decode_cell_data<T: Into<TypeOptionCellData>>(
        &self,
        type_option_cell_data: T,
        decoded_field_type: &FieldType,
        field_meta: &FieldMeta,
    ) -> DecodedCellData {
        let type_option_cell_data = type_option_cell_data.into();
        if decoded_field_type.is_date()
            || decoded_field_type.is_single_select()
            || decoded_field_type.is_multi_select()
            || decoded_field_type.is_number()
        {
            let field_type = type_option_cell_data.field_type.clone();
            decode_cell_data(type_option_cell_data, field_meta, &field_type).unwrap_or_default()
        } else {
            DecodedCellData::from_content(type_option_cell_data.data)
        }
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_meta: Option<CellMeta>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let data = changeset.into();
        if data.len() > 10000 {
            Err(FlowyError::text_too_long().context("The len of the text should not be more than 10000"))
        } else {
            Ok(data.0)
        }
    }
}

// #[cfg(test)]
// mod tests {
//     use crate::services::field::FieldBuilder;
//     use crate::services::field::*;
//     use crate::services::row::{CellDataOperation, TypeOptionCellData};
//     use flowy_grid_data_model::entities::FieldType;
//
//     #[test]
//     fn text_description_test() {
//         let type_option = RichTextTypeOption::default();
//
//         // date
//         let date_time_field_meta = FieldBuilder::from_field_type(&FieldType::DateTime).build();
//         let json = serde_json::to_string(&DateCellDataSerde::from_timestamp(1647251762, None)).unwrap();
//         let data = TypeOptionCellData::new(&json, FieldType::DateTime).json();
//         assert_eq!(
//             type_option.decode_cell_data(data, &date_time_field_meta).content,
//             "Mar 14,2022".to_owned()
//         );
//
//         // Single select
//         let done_option = SelectOption::new("Done");
//         let done_option_id = done_option.id.clone();
//         let single_select = SingleSelectTypeOptionBuilder::default().option(done_option);
//         let single_select_field_meta = FieldBuilder::new(single_select).build();
//         let cell_data = TypeOptionCellData::new(&done_option_id, FieldType::SingleSelect).json();
//         assert_eq!(
//             type_option
//                 .decode_cell_data(cell_data, &single_select_field_meta)
//                 .content,
//             "Done".to_owned()
//         );
//
//         // Multiple select
//         let google_option = SelectOption::new("Google");
//         let facebook_option = SelectOption::new("Facebook");
//         let ids = vec![google_option.id.clone(), facebook_option.id.clone()].join(SELECTION_IDS_SEPARATOR);
//         let cell_data_changeset = SelectOptionCellContentChangeset::from_insert(&ids).to_str();
//         let multi_select = MultiSelectTypeOptionBuilder::default()
//             .option(google_option)
//             .option(facebook_option);
//         let multi_select_field_meta = FieldBuilder::new(multi_select).build();
//         let multi_type_option = MultiSelectTypeOption::from(&multi_select_field_meta);
//         let cell_data = multi_type_option.apply_changeset(cell_data_changeset, None).unwrap();
//         assert_eq!(
//             type_option
//                 .decode_cell_data(cell_data, &multi_select_field_meta)
//                 .content,
//             "Google,Facebook".to_owned()
//         );
//
//         //Number
//         let number = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
//         let number_field_meta = FieldBuilder::new(number).build();
//         let data = TypeOptionCellData::new("18443", FieldType::Number).json();
//         assert_eq!(
//             type_option.decode_cell_data(data, &number_field_meta).content,
//             "$18,443".to_owned()
//         );
//     }
// }
