use crate::entities::FieldType;
use crate::impl_type_option;
use crate::services::cell::{AnyCellChangeset, CellBytes, CellData, CellDataOperation, CellDisplayable};
use crate::services::field::{BoxTypeOptionBuilder, TypeOptionBuilder, URLCellDataPB};
use bytes::Bytes;
use fancy_regex::Regex;
use flowy_derive::ProtoBuf;
use flowy_error::{FlowyError, FlowyResult};
use grid_rev_model::{CellRevision, FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};

#[derive(Default)]
pub struct URLTypeOptionBuilder(URLTypeOptionPB);
impl_into_box_type_option_builder!(URLTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(URLTypeOptionBuilder, URLTypeOptionPB);

impl TypeOptionBuilder for URLTypeOptionBuilder {
    fn field_type(&self) -> FieldType {
        FieldType::URL
    }

    fn serializer(&self) -> &dyn TypeOptionDataSerializer {
        &self.0
    }

    fn transform(&mut self, _field_type: &FieldType, _type_option_data: String) {
        // Do nothing
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct URLTypeOptionPB {
    #[pb(index = 1)]
    data: String, //It's not used yet.
}
impl_type_option!(URLTypeOptionPB, FieldType::URL);

impl CellDisplayable<URLCellDataPB> for URLTypeOptionPB {
    fn displayed_cell_bytes(
        &self,
        cell_data: CellData<URLCellDataPB>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        let cell_data: URLCellDataPB = cell_data.try_into_inner()?;
        CellBytes::from(cell_data)
    }

    fn displayed_cell_string(
        &self,
        cell_data: CellData<URLCellDataPB>,
        _decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<String> {
        let cell_data: URLCellDataPB = cell_data.try_into_inner()?;
        Ok(cell_data.content)
    }
}

impl CellDataOperation<URLCellDataPB, String> for URLTypeOptionPB {
    fn decode_cell_data(
        &self,
        cell_data: CellData<URLCellDataPB>,
        decoded_field_type: &FieldType,
        field_rev: &FieldRevision,
    ) -> FlowyResult<CellBytes> {
        if !decoded_field_type.is_url() {
            return Ok(CellBytes::default());
        }
        self.displayed_cell_bytes(cell_data, decoded_field_type, field_rev)
    }

    fn apply_changeset(
        &self,
        changeset: AnyCellChangeset<String>,
        _cell_rev: Option<CellRevision>,
    ) -> Result<String, FlowyError> {
        let content = changeset.try_into_inner()?;
        let mut url = "".to_string();
        if let Ok(Some(m)) = URL_REGEX.find(&content) {
            url = auto_append_scheme(m.as_str());
        }
        URLCellDataPB { url, content }.to_json()
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
