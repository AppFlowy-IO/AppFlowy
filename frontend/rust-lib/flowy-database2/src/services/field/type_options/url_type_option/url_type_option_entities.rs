use bytes::Bytes;
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};
use serde::{Deserialize, Serialize};

use flowy_error::{internal_error, FlowyResult};

use crate::entities::{FieldType, URLCellDataPB};
use crate::services::cell::CellProtobufBlobParser;
use crate::services::field::{TypeOptionCellData, CELL_DATA};

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct URLCellData {
  pub url: String,
  pub data: String,
}

impl URLCellData {
  pub fn new(s: &str) -> Self {
    Self {
      url: "".to_string(),
      data: s.to_string(),
    }
  }

  pub fn to_json(&self) -> FlowyResult<String> {
    serde_json::to_string(self).map_err(internal_error)
  }
}

impl TypeOptionCellData for URLCellData {
  fn is_cell_empty(&self) -> bool {
    self.data.is_empty()
  }
}

impl From<&Cell> for URLCellData {
  fn from(cell: &Cell) -> Self {
    let url = cell.get_str_value("url").unwrap_or_default();
    let content = cell.get_str_value(CELL_DATA).unwrap_or_default();
    Self { url, data: content }
  }
}

impl From<URLCellData> for Cell {
  fn from(data: URLCellData) -> Self {
    new_cell_builder(FieldType::URL)
      .insert_str_value("url", data.url)
      .insert_str_value(CELL_DATA, data.data)
      .build()
  }
}

impl From<URLCellData> for URLCellDataPB {
  fn from(data: URLCellData) -> Self {
    Self {
      url: data.url,
      content: data.data,
    }
  }
}

impl From<URLCellDataPB> for URLCellData {
  fn from(data: URLCellDataPB) -> Self {
    Self {
      url: data.url,
      data: data.content,
    }
  }
}

impl AsRef<str> for URLCellData {
  fn as_ref(&self) -> &str {
    &self.url
  }
}

pub struct URLCellDataParser();
impl CellProtobufBlobParser for URLCellDataParser {
  type Object = URLCellDataPB;

  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    URLCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
  }
}

impl ToString for URLCellData {
  fn to_string(&self) -> String {
    self.to_json().unwrap()
  }
}
