use std::str::FromStr;

use bytes::Bytes;
use collab::util::AnyMapExt;
use collab_database::rows::{new_cell_builder, Cell};

use flowy_error::{FlowyError, FlowyResult};

use crate::entities::{CheckboxCellDataPB, FieldType};
use crate::services::cell::CellProtobufBlobParser;
use crate::services::field::{TypeOptionCellData, CELL_DATA};

pub const CHECK: &str = "Yes";
pub const UNCHECK: &str = "No";

impl TypeOptionCellData for CheckboxCellDataPB {
  fn is_cell_empty(&self) -> bool {
    false
  }
}

impl From<&Cell> for CheckboxCellDataPB {
  fn from(cell: &Cell) -> Self {
    let value: String = cell.get_as(CELL_DATA).unwrap_or_default();
    CheckboxCellDataPB::from_str(&value).unwrap_or_default()
  }
}

impl From<CheckboxCellDataPB> for Cell {
  fn from(data: CheckboxCellDataPB) -> Self {
    let mut cell = new_cell_builder(FieldType::Checkbox);
    cell.insert(CELL_DATA.into(), data.to_string().into());
    cell
  }
}

impl FromStr for CheckboxCellDataPB {
  type Err = FlowyError;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    let lower_case_str: &str = &s.to_lowercase();
    let is_checked = match lower_case_str {
      "1" | "true" | "yes" => true,
      "0" | "false" | "no" => false,
      _ => false,
    };

    Ok(Self::new(is_checked))
  }
}

impl ToString for CheckboxCellDataPB {
  fn to_string(&self) -> String {
    if self.is_checked {
      CHECK.to_string()
    } else {
      UNCHECK.to_string()
    }
  }
}

pub struct CheckboxCellDataParser();
impl CellProtobufBlobParser for CheckboxCellDataParser {
  type Object = CheckboxCellDataPB;

  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    CheckboxCellDataPB::try_from(bytes.as_ref()).or_else(|_| Ok(CheckboxCellDataPB::default()))
  }
}
