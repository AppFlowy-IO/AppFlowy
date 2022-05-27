use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellContentChangeset, CellDataOperation, DecodedCellData};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};

use serde::{Deserialize, Serialize};

#[derive(Default)]
pub struct URLTypeOptionBuilder(URLTypeOption);
impl_into_box_type_option_builder!(URLTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(URLTypeOptionBuilder, URLTypeOption);

impl TypeOptionBuilder for URLTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        self.0.field_type()
    }

    fn entry(&self) -> &dyn TypeOptionDataEntry {
        &self.0
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct URLTypeOption {
    #[pb(index = 1)]
    data: String, //It's not used.
}
impl_type_option!(URLTypeOption, FieldType::URL);

impl CellDataOperation<String, String> for URLTypeOption {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        _field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<String>,
    {
        if !decoded_field_type.is_url() {
            return Ok(DecodedCellData::default());
        }

        let cell_data = encoded_data.into();
        Ok(DecodedCellData::from_content(cell_data))
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_meta: Option<CellMeta>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let changeset = changeset.into();
        Ok(changeset.to_string())
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct URLCellData {
    #[pb(index = 1)]
    pub url: String,

    #[pb(index = 2)]
    pub content: String,
}

#[cfg(test)]
mod tests {
    use crate::services::field::FieldBuilder;
    use crate::services::field::URLTypeOption;
    use crate::services::row::CellDataOperation;
    use flowy_grid_data_model::entities::{FieldMeta, FieldType};

    #[test]
    fn url_type_option_format_test() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();
        assert_equal(&type_option, "123", "123", &field_type, &field_meta);
    }

    fn assert_equal(
        type_option: &URLTypeOption,
        cell_data: &str,
        expected_str: &str,
        field_type: &FieldType,
        field_meta: &FieldMeta,
    ) {
        assert_eq!(
            type_option
                .decode_cell_data(cell_data, field_type, field_meta)
                .unwrap()
                .content,
            expected_str.to_owned()
        );
    }
}
