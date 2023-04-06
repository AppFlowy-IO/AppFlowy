use crate::entities::{FieldType, URLCellDataPB};
use crate::services::cell::{CellProtobufBlobParser, DecodedCellData, FromCellString};
use bytes::Bytes;
use collab::core::lib0_any_ext::Lib0AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};
use flowy_error::{internal_error, FlowyResult};
use serde::{Deserialize, Serialize};

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

impl From<&Cell> for URLCellData {
  fn from(cell: &Cell) -> Self {
    let url = cell.get_str_value("url").unwrap_or_default();
    let content = cell.get_str_value("content").unwrap_or_default();
    Self { url, content }
  }
}

impl From<URLCellData> for Cell {
  fn from(data: URLCellData) -> Self {
    new_cell_builder(FieldType::URL)
      .insert_str_value("url", data.url)
      .insert_str_value("content", data.content)
      .build()
  }
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

impl From<URLCellDataPB> for URLCellData {
  fn from(data: URLCellDataPB) -> Self {
    Self {
      url: data.url,
      content: data.content,
    }
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
    self.to_json().unwrap()
  }
}
