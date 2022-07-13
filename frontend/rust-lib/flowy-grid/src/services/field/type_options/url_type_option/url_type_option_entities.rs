use crate::services::cell::{CellBytesParser, FromCellString};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{internal_error, FlowyResult};
use serde::{Deserialize, Serialize};

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

    pub(crate) fn to_json(&self) -> FlowyResult<String> {
        serde_json::to_string(self).map_err(internal_error)
    }
}

pub struct URLCellDataParser();
impl CellBytesParser for URLCellDataParser {
    type Object = URLCellData;

    fn parse(&self, bytes: &Bytes) -> FlowyResult<Self::Object> {
        URLCellData::try_from(bytes.as_ref()).map_err(internal_error)
    }
}

impl FromCellString for URLCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self> {
        serde_json::from_str::<URLCellData>(s).map_err(internal_error)
    }
}
