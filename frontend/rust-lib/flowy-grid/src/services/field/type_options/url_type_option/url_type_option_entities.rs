use crate::services::cell::{CellBytesParser, CellDataIsEmpty, FromCellString};
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

#[derive(Clone, Default, Serialize, Deserialize)]
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

    pub(crate) fn to_json(&self) -> FlowyResult<String> {
        serde_json::to_string(self).map_err(internal_error)
    }
}

impl CellDataIsEmpty for URLCellData {
    fn is_empty(&self) -> bool {
        self.content.is_empty()
    }
}

pub struct URLCellDataParser();
impl CellBytesParser for URLCellDataParser {
    type Object = URLCellData;

    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        match String::from_utf8(bytes.to_vec()) {
            Ok(s) => URLCellData::from_cell_str(&s),
            Err(_) => Ok(URLCellData::default()),
        }
    }
}

impl FromCellString for URLCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self> {
        serde_json::from_str::<URLCellData>(s).map_err(internal_error)
    }
}
