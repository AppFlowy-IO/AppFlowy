use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{decode_cell_data, CellContentChangeset, CellDataOperation, DecodedCellData};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
use serde::{Deserialize, Serialize};

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
    data: String, //It's not used yet
}
impl_type_option!(RichTextTypeOption, FieldType::RichText);

impl CellDataOperation<String, String> for RichTextTypeOption {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<String>,
    {
        if decoded_field_type.is_date()
            || decoded_field_type.is_single_select()
            || decoded_field_type.is_multi_select()
            || decoded_field_type.is_number()
        {
            decode_cell_data(encoded_data, decoded_field_type, decoded_field_type, field_meta)
        } else {
            let cell_data = encoded_data.into();
            Ok(DecodedCellData::new(cell_data))
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

#[cfg(test)]
mod tests {
    use crate::services::field::FieldBuilder;
    use crate::services::field::*;
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::entities::FieldType;

    #[test]
    fn text_description_test() {
        let type_option = RichTextTypeOption::default();

        // date
        let field_type = FieldType::DateTime;
        let date_time_field_meta = FieldBuilder::from_field_type(&field_type).build();
        let json = serde_json::to_string(&DateCellDataSerde::from_timestamp(1647251762, None)).unwrap();
        assert_eq!(
            type_option
                .decode_cell_data(json, &field_type, &date_time_field_meta)
                .unwrap()
                .parse::<DateCellData>()
                .unwrap()
                .date,
            "Mar 14,2022".to_owned()
        );

        // Single select
        let done_option = SelectOption::new("Done");
        let done_option_id = done_option.id.clone();
        let single_select = SingleSelectTypeOptionBuilder::default().option(done_option.clone());
        let single_select_field_meta = FieldBuilder::new(single_select).build();

        assert_eq!(
            type_option
                .decode_cell_data(done_option_id, &FieldType::SingleSelect, &single_select_field_meta)
                .unwrap()
                .parse::<SelectOptionCellData>()
                .unwrap()
                .select_options,
            vec![done_option],
        );

        // Multiple select
        let google_option = SelectOption::new("Google");
        let facebook_option = SelectOption::new("Facebook");
        let ids = vec![google_option.id.clone(), facebook_option.id.clone()].join(SELECTION_IDS_SEPARATOR);
        let cell_data_changeset = SelectOptionCellContentChangeset::from_insert(&ids).to_str();
        let multi_select = MultiSelectTypeOptionBuilder::default()
            .option(google_option.clone())
            .option(facebook_option.clone());
        let multi_select_field_meta = FieldBuilder::new(multi_select).build();
        let multi_type_option = MultiSelectTypeOption::from(&multi_select_field_meta);
        let cell_data = multi_type_option.apply_changeset(cell_data_changeset, None).unwrap();
        assert_eq!(
            type_option
                .decode_cell_data(cell_data, &FieldType::MultiSelect, &multi_select_field_meta)
                .unwrap()
                .parse::<SelectOptionCellData>()
                .unwrap()
                .select_options,
            vec![google_option, facebook_option]
        );

        //Number
        let number = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
        let number_field_meta = FieldBuilder::new(number).build();
        assert_eq!(
            type_option
                .decode_cell_data("18443".to_owned(), &FieldType::Number, &number_field_meta)
                .unwrap()
                .to_string(),
            "$18,443".to_owned()
        );
    }
}
