use crate::services::cell::{CellProtobufBlobParser, DecodedCellData, FromCellString};
use bytes::Bytes;
use flowy_error::{FlowyError, FlowyResult};
use protobuf::ProtobufError;
use std::str::FromStr;

pub const CHECK: &str = "Yes";
pub const UNCHECK: &str = "No";

#[derive(Default, Debug, Clone)]
pub struct CheckboxCellData(String);

impl CheckboxCellData {
  pub fn is_check(&self) -> bool {
    self.0 == CHECK
  }

  pub fn is_uncheck(&self) -> bool {
    self.0 == UNCHECK
  }
}

impl AsRef<[u8]> for CheckboxCellData {
  fn as_ref(&self) -> &[u8] {
    self.0.as_ref()
  }
}

impl FromStr for CheckboxCellData {
  type Err = FlowyError;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    let lower_case_str: &str = &s.to_lowercase();
    let val = match lower_case_str {
      "1" => Some(true),
      "true" => Some(true),
      "yes" => Some(true),
      "0" => Some(false),
      "false" => Some(false),
      "no" => Some(false),
      _ => None,
    };

    match val {
      Some(true) => Ok(Self(CHECK.to_string())),
      Some(false) => Ok(Self(UNCHECK.to_string())),
      None => Ok(Self("".to_string())),
    }
  }
}

impl std::convert::TryFrom<CheckboxCellData> for Bytes {
  type Error = ProtobufError;

  fn try_from(value: CheckboxCellData) -> Result<Self, Self::Error> {
    Ok(Bytes::from(value.0))
  }
}

impl FromCellString for CheckboxCellData {
  fn from_cell_str(s: &str) -> FlowyResult<Self>
  where
    Self: Sized,
  {
    Self::from_str(s)
  }
}

impl ToString for CheckboxCellData {
  fn to_string(&self) -> String {
    self.0.clone()
  }
}

impl DecodedCellData for CheckboxCellData {
  type Object = CheckboxCellData;

  fn is_empty(&self) -> bool {
    self.0.is_empty()
  }
}

pub struct CheckboxCellDataParser();
impl CellProtobufBlobParser for CheckboxCellDataParser {
  type Object = CheckboxCellData;
  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    match String::from_utf8(bytes.to_vec()) {
      Ok(s) => CheckboxCellData::from_cell_str(&s),
      Err(_) => Ok(CheckboxCellData("".to_string())),
    }
  }
}
