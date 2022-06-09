use crate::impl_type_option;
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder};
use crate::services::row::{CellContentChangeset, CellDataOperation, DecodedCellData, EncodedCellData};
use bytes::Bytes;
use fancy_regex::Regex;
use flowy_derive::ProtoBuf;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    CellMeta, FieldMeta, FieldType, TypeOptionDataDeserializer, TypeOptionDataEntry,
};
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

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
    data: String, //It's not used yet.
}
impl_type_option!(URLTypeOption, FieldType::URL);

impl CellDataOperation<EncodedCellData<URLCellData>> for URLTypeOption {
    fn decode_cell_data<T>(
        &self,
        encoded_data: T,
        decoded_field_type: &FieldType,
        _field_meta: &FieldMeta,
    ) -> FlowyResult<DecodedCellData>
    where
        T: Into<EncodedCellData<URLCellData>>,
    {
        if !decoded_field_type.is_url() {
            return Ok(DecodedCellData::default());
        }
        let cell_data = encoded_data.into().try_into_inner()?;
        DecodedCellData::try_from_bytes(cell_data)
    }

    fn apply_changeset<C>(&self, changeset: C, _cell_meta: Option<CellMeta>) -> Result<String, FlowyError>
    where
        C: Into<CellContentChangeset>,
    {
        let changeset = changeset.into();
        let mut url = "".to_string();
        if let Ok(Some(m)) = URL_REGEX.find(&changeset) {
            url = auto_append_scheme(m.as_str());
        }
        URLCellData {
            url,
            content: changeset.to_string(),
        }
        .to_json()
    }
}

fn auto_append_scheme(s: &str) -> String {
    // Only support https scheme by now
    match url::Url::parse(s) {
        Ok(url) => {
            if url.scheme() == "https" {
                url.into()
            } else {
                format!("https://{}", s)
            }
        }
        Err(_) => {
            format!("https://{}", s)
        }
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct URLCellData {
    #[pb(index = 1)]
    pub url: String,

    #[pb(index = 2)]
    pub content: String,
}

impl URLCellData {
    pub fn new(s: &str) -> Self {
        Self {
            url: "".to_string(),
            content: s.to_string(),
        }
    }

    fn to_json(&self) -> FlowyResult<String> {
        serde_json::to_string(self).map_err(internal_error)
    }
}

impl FromStr for URLCellData {
    type Err = FlowyError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        serde_json::from_str::<URLCellData>(s).map_err(internal_error)
    }
}

lazy_static! {
    static ref URL_REGEX: Regex = Regex::new(
        "[(http(s)?):\\/\\/(www\\.)?a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
    )
    .unwrap();
}

#[cfg(test)]
mod tests {
    use crate::services::field::FieldBuilder;
    use crate::services::field::{URLCellData, URLTypeOption};
    use crate::services::row::{CellDataOperation, EncodedCellData};
    use flowy_grid_data_model::entities::{FieldMeta, FieldType};

    #[test]
    fn url_type_option_test_no_url() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset(&type_option, "123", &field_type, &field_meta, "123", "");
    }

    #[test]
    fn url_type_option_test_contains_url() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_meta = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset(
            &type_option,
            "AppFlowy website - https://www.appflowy.io",
            &field_type,
            &field_meta,
            "AppFlowy website - https://www.appflowy.io",
            "https://www.appflowy.io/",
        );

        assert_changeset(
            &type_option,
            "AppFlowy website appflowy.io",
            &field_type,
            &field_meta,
            "AppFlowy website appflowy.io",
            "https://appflowy.io",
        );
    }

    fn assert_changeset(
        type_option: &URLTypeOption,
        cell_data: &str,
        field_type: &FieldType,
        field_meta: &FieldMeta,
        expected: &str,
        expected_url: &str,
    ) {
        let encoded_data = type_option.apply_changeset(cell_data, None).unwrap();
        let decode_cell_data = decode_cell_data(encoded_data, type_option, field_meta, field_type);
        assert_eq!(expected.to_owned(), decode_cell_data.content);
        assert_eq!(expected_url.to_owned(), decode_cell_data.url);
    }

    fn decode_cell_data<T: Into<EncodedCellData<URLCellData>>>(
        encoded_data: T,
        type_option: &URLTypeOption,
        field_meta: &FieldMeta,
        field_type: &FieldType,
    ) -> URLCellData {
        type_option
            .decode_cell_data(encoded_data, field_type, field_meta)
            .unwrap()
            .parse::<URLCellData>()
            .unwrap()
    }
}
