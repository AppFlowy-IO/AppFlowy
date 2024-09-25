use bytes::Bytes;

use collab_database::fields::url_type_option::URLCellData;

use flowy_error::{internal_error, FlowyResult};

use crate::entities::URLCellDataPB;
use crate::services::cell::CellProtobufBlobParser;
use crate::services::field::TypeOptionCellData;

impl TypeOptionCellData for URLCellData {
  fn is_cell_empty(&self) -> bool {
    self.data.is_empty()
  }
}

impl From<URLCellData> for URLCellDataPB {
  fn from(data: URLCellData) -> Self {
    Self { content: data.data }
  }
}

impl From<URLCellDataPB> for URLCellData {
  fn from(data: URLCellDataPB) -> Self {
    Self { data: data.content }
  }
}

pub struct URLCellDataParser();
impl CellProtobufBlobParser for URLCellDataParser {
  type Object = URLCellDataPB;

  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    URLCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
  }
}
