use collab::util::AnyMapExt;
use collab_database::rows::{new_cell_builder, Cell};
use serde::Serialize;

use crate::{
  entities::FieldType,
  services::field::{TypeOptionCellData, CELL_DATA},
};

#[derive(Clone, Debug, Default, Serialize)]
pub struct TimestampCellData {
  pub timestamp: Option<i64>,
}

impl TimestampCellData {
  pub fn new(timestamp: i64) -> Self {
    Self {
      timestamp: Some(timestamp),
    }
  }
}

impl From<&Cell> for TimestampCellData {
  fn from(cell: &Cell) -> Self {
    let timestamp = cell
      .get_as::<String>(CELL_DATA)
      .and_then(|data| data.parse::<i64>().ok());
    Self { timestamp }
  }
}

/// Wrapper for DateCellData that also contains the field type.
/// Handy struct to use when you need to convert a DateCellData to a Cell.
pub struct TimestampCellDataWrapper {
  data: TimestampCellData,
  field_type: FieldType,
}

impl From<(FieldType, TimestampCellData)> for TimestampCellDataWrapper {
  fn from((field_type, data): (FieldType, TimestampCellData)) -> Self {
    Self { data, field_type }
  }
}

impl From<TimestampCellDataWrapper> for Cell {
  fn from(wrapper: TimestampCellDataWrapper) -> Self {
    let (field_type, data) = (wrapper.field_type, wrapper.data);
    let timestamp_string = data.timestamp.unwrap_or_default();

    let mut cell = new_cell_builder(field_type);
    cell.insert(CELL_DATA.into(), timestamp_string.into());
    cell
  }
}

impl From<TimestampCellData> for Cell {
  fn from(data: TimestampCellData) -> Self {
    let data: TimestampCellDataWrapper = (FieldType::LastEditedTime, data).into();
    Cell::from(data)
  }
}

impl TypeOptionCellData for TimestampCellData {}

impl ToString for TimestampCellData {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}
