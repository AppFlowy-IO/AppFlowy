use crate::services::cell::{CellProtobufBlobParser, DecodedCellData, FromCellString};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{internal_error, FlowyResult};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct URLCellDataPB {
    #[pb(index = 1)]
    pub url: String,

    #[pb(index = 2)]
    pub content: String,
}

impl From<URLCellData> for URLCellDataPB {
    fn from(data: URLCellData) -> Self {
        Self {
            url: data.url,
            content: data.content,
        }
    }
}

impl DecodedCellData for URLCellDataPB {
    type Object = URLCellDataPB;

    fn is_empty(&self) -> bool {
        self.content.is_empty()
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct URLCellData {
    pub url: String,
    pub content: String,
}

impl URLCellData {
    pub fn new(s: &str) -> Self {
        Self {
            url: "".to_string(),
            content: s.to_string(),
        }
    }

    pub fn to_json(&self) -> FlowyResult<String> {
        serde_json::to_string(self).map_err(internal_error)
    }
}

impl AsRef<str> for URLCellData {
    fn as_ref(&self) -> &str {
        &self.url
    }
}

impl DecodedCellData for URLCellData {
    type Object = URLCellData;

    fn is_empty(&self) -> bool {
        self.content.is_empty()
    }
}

pub struct URLCellDataParser();
impl CellProtobufBlobParser for URLCellDataParser {
    type Object = URLCellDataPB;

    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        URLCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
    }
}

impl FromCellString for URLCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self> {
        serde_json::from_str::<URLCellData>(s).map_err(internal_error)
    }
}

impl ToString for URLCellData {
    fn to_string(&self) -> String {
        self.content.clone()
    }
}
