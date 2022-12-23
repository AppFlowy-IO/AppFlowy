use crate::entities::{FieldType, TextFilterPB};
use crate::impl_type_option;
use crate::services::cell::{CellDataChangeset, CellDataDecoder, FromCellString, TypeCellData};
use crate::services::field::{
    BoxTypeOptionBuilder, TypeOption, TypeOptionBuilder, TypeOptionCellData, TypeOptionConfiguration,
    TypeOptionTransform, URLCellData, URLCellDataPB,
};
use bytes::Bytes;
use fancy_regex::Regex;
use flowy_derive::ProtoBuf;
use flowy_error::FlowyResult;
use grid_rev_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
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
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, ProtoBuf)]
pub struct URLTypeOptionPB {
    #[pb(index = 1)]
    data: String, //It's not used yet.
}
impl_type_option!(URLTypeOptionPB, FieldType::URL);

impl TypeOption for URLTypeOptionPB {
    type CellData = URLCellData;
    type CellChangeset = URLCellChangeset;
    type CellProtobufType = URLCellDataPB;
}

impl TypeOptionTransform for URLTypeOptionPB {}

impl TypeOptionConfiguration for URLTypeOptionPB {
    type CellFilterConfiguration = TextFilterPB;
}

impl TypeOptionCellData for URLTypeOptionPB {
    fn convert_to_protobuf(&self, cell_data: <Self as TypeOption>::CellData) -> <Self as TypeOption>::CellProtobufType {
        cell_data.into()
    }

    fn decode_type_option_cell_str(&self, cell_str: String) -> FlowyResult<<Self as TypeOption>::CellData> {
        URLCellData::from_cell_str(&cell_str)
    }
}

impl CellDataDecoder for URLTypeOptionPB {
    fn decode_cell_str(
        &self,
        cell_str: String,
        decoded_field_type: &FieldType,
        _field_rev: &FieldRevision,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        if !decoded_field_type.is_url() {
            return Ok(Default::default());
        }

        self.decode_type_option_cell_str(cell_str)
    }

    fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
        cell_data.content
    }
}

pub type URLCellChangeset = String;

impl CellDataChangeset for URLTypeOptionPB {
    fn apply_changeset(
        &self,
        changeset: <Self as TypeOption>::CellChangeset,
        _type_cell_data: Option<TypeCellData>,
    ) -> FlowyResult<<Self as TypeOption>::CellData> {
        let mut url = "".to_string();
        if let Ok(Some(m)) = URL_REGEX.find(&changeset) {
            url = auto_append_scheme(m.as_str());
        }
        Ok(URLCellData {
            url,
            content: changeset,
        })
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
