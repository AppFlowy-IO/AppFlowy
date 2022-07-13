use crate::services::cell::{AnyCellData, FromCellString};
use flowy_derive::ProtoBuf;
use flowy_error::{internal_error, FlowyError, FlowyResult};
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

impl FromCellString for URLCellData {
    fn from_cell_str(s: &str) -> FlowyResult<Self> {
        serde_json::from_str::<URLCellData>(s).map_err(internal_error)
    }
}

impl std::convert::TryFrom<AnyCellData> for URLCellData {
    type Error = FlowyError;

    fn try_from(data: AnyCellData) -> Result<Self, Self::Error> {
        serde_json::from_str::<URLCellData>(&data.data).map_err(internal_error)
    }
}
