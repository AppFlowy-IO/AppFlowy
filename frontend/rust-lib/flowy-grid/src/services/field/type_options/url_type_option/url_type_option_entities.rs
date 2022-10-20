use crate::services::cell::{CellBytesParser, CellDataIsEmpty, FromCellString};
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error::{internal_error, FlowyResult};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct URLCellDataPB {
    #[pb(index = 1)]
    pub url: String,

    #[pb(index = 2)]
    pub content: String,
}

impl URLCellDataPB {
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

impl CellDataIsEmpty for URLCellDataPB {
    fn is_empty(&self) -> bool {
        self.content.is_empty()
    }
}

pub struct URLCellDataParser();
impl CellBytesParser for URLCellDataParser {
    type Object = URLCellDataPB;

    fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
        URLCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
    }
}

impl FromCellString for URLCellDataPB {
    fn from_cell_str(s: &str) -> FlowyResult<Self> {
        serde_json::from_str::<URLCellDataPB>(s).map_err(internal_error)
    }
}
