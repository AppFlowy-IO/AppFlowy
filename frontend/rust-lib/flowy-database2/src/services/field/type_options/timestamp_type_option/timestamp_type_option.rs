use std::cmp::Ordering;

use chrono::{DateTime, Local, Offset};
use collab::preclude::Any;
use collab::util::AnyMapExt;
use collab_database::fields::time_type_option::{DateFormat, TimeFormat};
use collab_database::fields::{TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use serde::{Deserialize, Serialize};

use crate::entities::{DateFilterPB, FieldType, TimestampCellDataPB};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, TimestampCellData, TypeOption, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionCellDataSerde, TypeOptionTransform,
};
use crate::services::sort::SortCondition;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TimestampTypeOption {
  pub date_format: DateFormat,
  pub time_format: TimeFormat,
  pub include_time: bool,
  pub field_type: FieldType,
}

impl Default for TimestampTypeOption {
  fn default() -> Self {
    Self {
      date_format: Default::default(),
      time_format: Default::default(),
      include_time: true,
      field_type: FieldType::LastEditedTime,
    }
  }
}

impl TypeOption for TimestampTypeOption {
  type CellData = TimestampCellData;
  type CellChangeset = String;
  type CellProtobufType = TimestampCellDataPB;
  type CellFilter = DateFilterPB;
}

impl From<TypeOptionData> for TimestampTypeOption {
  fn from(data: TypeOptionData) -> Self {
    let date_format = data
      .get_as::<i64>("date_format")
      .map(DateFormat::from)
      .unwrap_or_default();
    let time_format = data
      .get_as::<i64>("time_format")
      .map(TimeFormat::from)
      .unwrap_or_default();
    let include_time = data.get_as::<bool>("include_time").unwrap_or_default();
    let field_type = data
      .get_as::<i64>("field_type")
      .map(FieldType::from)
      .unwrap_or(FieldType::LastEditedTime);
    Self {
      date_format,
      time_format,
      include_time,
      field_type,
    }
  }
}

impl From<TimestampTypeOption> for TypeOptionData {
  fn from(option: TimestampTypeOption) -> Self {
    TypeOptionDataBuilder::from([
      (
        "date_format".into(),
        Any::BigInt(option.date_format.value()),
      ),
      (
        "time_format".into(),
        Any::BigInt(option.time_format.value()),
      ),
      ("include_time".into(), Any::Bool(option.include_time)),
      ("field_type".into(), Any::BigInt(option.field_type.value())),
    ])
  }
}

impl TypeOptionCellDataSerde for TimestampTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let timestamp = cell_data.timestamp;
    let date_time = self.stringify_cell_data(cell_data);

    TimestampCellDataPB {
      date_time,
      timestamp,
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(TimestampCellData::from(cell))
  }
}

impl TimestampTypeOption {
  pub fn new(field_type: FieldType) -> Self {
    Self {
      field_type,
      include_time: true,
      ..Default::default()
    }
  }

  fn formatted_date_time_from_timestamp(&self, timestamp: &Option<i64>) -> (String, String) {
    if let Some(timestamp) = timestamp {
      let naive = chrono::NaiveDateTime::from_timestamp_opt(*timestamp, 0).unwrap();
      let offset = Local::now().offset().fix();
      let date_time = DateTime::<Local>::from_naive_utc_and_offset(naive, offset);

      let fmt = self.date_format.format_str();
      let date = format!("{}", date_time.format(fmt));
      let fmt = self.time_format.format_str();
      let time = format!("{}", date_time.format(fmt));
      (date, time)
    } else {
      ("".to_owned(), "".to_owned())
    }
  }
}

impl TypeOptionTransform for TimestampTypeOption {}

impl CellDataDecoder for TimestampTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    let timestamp = cell_data.timestamp;
    let (date_string, time_string) = self.formatted_date_time_from_timestamp(&timestamp);
    if self.include_time {
      format!("{} {}", date_string, time_string)
    } else {
      date_string
    }
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}

impl CellDataChangeset for TimestampTypeOption {
  fn apply_changeset(
    &self,
    _changeset: <Self as TypeOption>::CellChangeset,
    _cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    Err(FlowyError::new(
      ErrorCode::FieldInvalidOperation,
      "Cells of this field type cannot be edited",
    ))
  }
}

impl TypeOptionCellDataFilter for TimestampTypeOption {
  fn apply_filter(
    &self,
    _filter: &<Self as TypeOption>::CellFilter,
    _cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    true
  }
}

impl TypeOptionCellDataCompare for TimestampTypeOption {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
    sort_condition: SortCondition,
  ) -> Ordering {
    match (cell_data.timestamp, other_cell_data.timestamp) {
      (Some(left), Some(right)) => {
        let order = left.cmp(&right);
        sort_condition.evaluate_order(order)
      },
      (Some(_), None) => Ordering::Less,
      (None, Some(_)) => Ordering::Greater,
      (None, None) => default_order(),
    }
  }
}
