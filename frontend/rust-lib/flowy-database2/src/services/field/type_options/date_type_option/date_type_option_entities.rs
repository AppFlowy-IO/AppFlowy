#![allow(clippy::upper_case_acronyms)]

use bytes::Bytes;
use collab_database::fields::time_type_option::DateCellData;
use flowy_error::{internal_error, FlowyResult};

use crate::entities::DateCellDataPB;
use crate::services::cell::CellProtobufBlobParser;
use crate::services::field::TypeOptionCellData;

#[derive(Clone, Debug, Default)]
pub struct DateCellChangeset {
  pub date: Option<i64>,
  pub time: Option<String>,
  pub end_date: Option<i64>,
  pub end_time: Option<String>,
  pub include_time: Option<bool>,
  pub is_range: Option<bool>,
  pub clear_flag: Option<bool>,
  pub reminder_id: Option<String>,
}

impl TypeOptionCellData for DateCellData {
  fn is_cell_empty(&self) -> bool {
    self.timestamp.is_none()
  }
}
pub struct DateCellDataParser();
impl CellProtobufBlobParser for DateCellDataParser {
  type Object = DateCellDataPB;

  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    DateCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
  }
}
