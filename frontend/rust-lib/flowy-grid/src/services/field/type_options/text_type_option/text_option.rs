use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{
    try_decode_cell_data, AnyCellData, CellBytes, CellData, CellDataChangeset, CellDataOperation, CellDisplayable,
};
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataEntry};
use serde::{Deserialize, Serialize};

#[derive(Default)]
pub struct RichTextTypeOptionBuilder(RichTextTypeOption);
impl_into_box_type_option_builder!(RichTextTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(RichTextTypeOptionBuilder, RichTextTypeOption);

impl TypeOptionBuilder for RichTextTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::RichText
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

impl CellDisplayable<String> for RichTextTypeOption {
    fn display_data(
        &self,
        cell_data: CellData<String>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_str: String = cell_data.try_into_inner()?;
        Ok(CellBytes::new(cell_str))
    }
}

impl CellDataOperation<String, String> for RichTextTypeOption {
    fn decode_cell_data(
        &self,
        cell_data: CellData<String>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if decoded_field_type.is_date()
            || decoded_field_type.is_single_select()
            || decoded_field_type.is_multi_select()
            || decoded_field_type.is_number()
        {
            try_decode_cell_data(cell_data, field_rev, decoded_field_type, decoded_field_type)
        } else {
            self.display_data(cell_data, decoded_field_type, field_rev)
        }
    }

    fn apply_changeset(
        &self,
        changeset: CellDataChangeset<String>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let data = changeset.try_into_inner()?;
        if data.len() > 10000 {
            Err(FlowyError::text_too_long().context("The len of the text should not be more than 10000"))
        } else {
            Ok(data)
        }
    }
}

pub struct TextCellData(pub String);
impl AsRef<str> for TextCellData {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl std::convert::TryFrom<AnyCellData> for TextCellData {
    type Error = FlowyError;

    fn try_from(value: AnyCellData) -> Result<Self, Self::Error> {
        Ok(TextCellData(value.data))
    }
}

#[cfg(test)]
mod tests {
    use crate::entities::FieldType;
    use crate::services::cell::CellDataOperation;
    
    use crate::services::field::FieldBuilder;
    use crate::services::field::*;

    #[test]
    fn text_description_test() {
        let type_option = RichTextTypeOption::default();

        // date
        let field_type = FieldType::DateTime;
        let date_time_field_rev = FieldBuilder::from_field_type(&field_type).build();

        assert_eq!(
            type_option
                .decode_cell_data(1647251762.to_string().into(), &field_type, &date_time_field_rev)
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
        let single_select_field_rev = FieldBuilder::new(single_select).build();

        assert_eq!(
            type_option
                .decode_cell_data(
                    done_option_id.into(),
                    &FieldType::SingleSelect,
                    &single_select_field_rev
                )
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
        let cell_data_changeset = SelectOptionCellChangeset::from_insert(&ids).to_str();
        let multi_select = MultiSelectTypeOptionBuilder::default()
            .option(google_option.clone())
            .option(facebook_option.clone());
        let multi_select_field_rev = FieldBuilder::new(multi_select).build();
        let multi_type_option = MultiSelectTypeOption::from(&multi_select_field_rev);
        let cell_data = multi_type_option
            .apply_changeset(cell_data_changeset.into(), None)
            .unwrap();
        assert_eq!(
            type_option
                .decode_cell_data(cell_data.into(), &FieldType::MultiSelect, &multi_select_field_rev)
                .unwrap()
                .parse::<SelectOptionCellData>()
                .unwrap()
                .select_options,
            vec![google_option, facebook_option]
        );

        //Number
        let number = NumberTypeOptionBuilder::default().set_format(NumberFormat::USD);
        let number_field_rev = FieldBuilder::new(number).build();
        assert_eq!(
            type_option
                .decode_cell_data("18443".to_owned().into(), &FieldType::Number, &number_field_rev)
                .unwrap()
                .to_string(),
            "$18,443".to_owned()
        );
    }
}
