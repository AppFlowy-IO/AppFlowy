use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{CellBytes, CellData, CellDataChangeset, CellDataOperation, CellDisplayable};
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder, URLCellData};
use bytes::Bytes;
use fancy_regex::Regex;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
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

impl CellDisplayable<URLCellData> for URLTypeOption {
    fn display_data(
        &self,
        cell_data: CellData<URLCellData>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_data: URLCellData = cell_data.try_into_inner()?;
        CellBytes::from(cell_data)
    }
}

impl CellDataOperation<URLCellData, String> for URLTypeOption {
    fn decode_cell_data(
        &self,
        cell_data: CellData<URLCellData>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if !decoded_field_type.is_url() {
            return Ok(CellBytes::default());
        }
        self.display_data(cell_data, decoded_field_type, field_rev)
    }

    fn apply_changeset(
        &self,
        changeset: CellDataChangeset<String>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let content = changeset.try_into_inner()?;
        let mut url = "".to_string();
        if let Ok(Some(m)) = URL_REGEX.find(&content) {
            url = auto_append_scheme(m.as_str());
        }
        URLCellData { url, content }.to_json()
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

lazy_static! {
    static ref URL_REGEX: Regex = Regex::new(
        "[(http(s)?):\\/\\/(www\\.)?a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
    )
    .unwrap();
}
