use crate::entities::{FieldType, GridTextFilter};
use crate::impl_type_option;
use crate::services::cell::{
    AnyCellData, CellData, CellDataChangeset, CellDataOperation, CellFilterOperation, DecodedCellData, FromCellString,
};
use crate::services::field::{BoxTypeOptionBuilder, TextCellData, TypeOptionBuilder};
use bytes::Bytes;
use fancy_regex::Regex;
use flowy_derive::ProtoBuf;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_grid_data_model::revision::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataEntry};
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};

#[derive(Default)]
pub struct URLTypeOptionBuilder(URLTypeOption);
impl_into_box_type_option_builder!(URLTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(URLTypeOptionBuilder, URLTypeOption);

impl TypeOptionBuilder for URLTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::URL
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

impl CellFilterOperation<GridTextFilter> for URLTypeOption {
    fn apply_filter(&self, any_cell_data: AnyCellData, filter: &GridTextFilter) -> FlowyResult<bool> {
        if !any_cell_data.is_url() {
            return Ok(true);
        }

        let text_cell_data: TextCellData = any_cell_data.try_into()?;
        Ok(filter.apply(&text_cell_data))
    }
}

impl CellDataOperation<URLCellData, String> for URLTypeOption {
    fn decode_cell_data(
        &self,
        cell_data: CellData<URLCellData>,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<DecodedCellData> {
        if !decoded_field_type.is_url() {
            return Ok(DecodedCellData::default());
        }
        let cell_data: URLCellData = cell_data.try_into_inner()?;
        DecodedCellData::try_from_bytes(cell_data)
    }

    fn apply_changeset(
        &self,
        changeset: CellDataChangeset<String>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let changeset = changeset.try_into_inner()?;
        let mut url = "".to_string();
        if let Ok(Some(m)) = URL_REGEX.find(&changeset) {
            url = auto_append_scheme(m.as_str());
        }
        URLCellData {
            url,
            content: changeset,
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

impl FromCellString for URLCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self> {
        serde_json::from_str::<URLCellData>(s).map_err(internal_error)
    }
}

impl std::convert::TryFrom<AnyCellData> for URLCellData {
    type Error = FlowyError;

    fn try_from(data: AnyCellData) -> Result<Self, Self::Error> {
        serde_json::from_str::<URLCellData>(&data.cell_data).map_err(internal_error)
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
    use crate::entities::FieldType;
    use crate::services::cell::{CellData, CellDataOperation};
    use crate::services::field::FieldBuilder;
    use crate::services::field::{URLCellData, URLTypeOption};
    use flowy_grid_data_model::revision::FieldRevision;

    #[test]
    fn url_type_option_test_no_url() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset(&type_option, "123", &field_type, &field_rev, "123", "");
    }

    #[test]
    fn url_type_option_test_contains_url() {
        let type_option = URLTypeOption::default();
        let field_type = FieldType::URL;
        let field_rev = FieldBuilder::from_field_type(&field_type).build();
        assert_changeset(
            &type_option,
            "AppFlowy website - https://www.appflowy.io",
            &field_type,
            &field_rev,
            "AppFlowy website - https://www.appflowy.io",
            "https://www.appflowy.io/",
        );

        assert_changeset(
            &type_option,
            "AppFlowy website appflowy.io",
            &field_type,
            &field_rev,
            "AppFlowy website appflowy.io",
            "https://appflowy.io",
        );
    }

    fn assert_changeset(
        type_option: &URLTypeOption,
        cell_data: &str,
        field_type: &FieldType,
        field_rev: &FieldRevision,
        expected: &str,
        expected_url: &str,
    ) {
        let encoded_data = type_option.apply_changeset(cell_data.to_owned().into(), None).unwrap();
        let decode_cell_data = decode_cell_data(encoded_data, type_option, field_rev, field_type);
        assert_eq!(expected.to_owned(), decode_cell_data.content);
        assert_eq!(expected_url.to_owned(), decode_cell_data.url);
    }

    fn decode_cell_data<T: Into<CellData<URLCellData>>>(
        encoded_data: T,
        type_option: &URLTypeOption,
        field_rev: &FieldRevision,
        field_type: &FieldType,
    ) -> URLCellData {
        type_option
            .decode_cell_data(encoded_data.into(), field_type, field_rev)
            .unwrap()
            .parse::<URLCellData>()
            .unwrap()
    }
}
