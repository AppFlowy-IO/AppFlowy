use std::cmp::Ordering;
use std::str::FromStr;

use chrono::{DateTime, FixedOffset, Local, NaiveDateTime, NaiveTime, Offset, TimeZone};
use chrono_tz::Tz;
use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use serde::{Deserialize, Serialize};

use flowy_error::{ErrorCode, FlowyError, FlowyResult};

use crate::entities::{DateCellDataPB, DateFilterPB, FieldType};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, DateCellChangeset, DateCellData, DateFormat, TimeFormat, TypeOption,
  TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionCellDataSerde,
  TypeOptionTransform,
};
use crate::services::sort::SortCondition;

/// The [DateTypeOption] is used by [FieldType::Date], [FieldType::LastEditedTime], and [FieldType::CreatedTime].
/// So, storing the field type is necessary to distinguish the field type.
/// Most of the cases, each [FieldType] has its own [TypeOption] implementation.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DateTypeOption {
  pub date_format: DateFormat,
  pub time_format: TimeFormat,
  pub timezone_id: String,
}

impl Default for DateTypeOption {
  fn default() -> Self {
    Self {
      date_format: Default::default(),
      time_format: Default::default(),
      timezone_id: Default::default(),
    }
  }
}

impl TypeOption for DateTypeOption {
  type CellData = DateCellData;
  type CellChangeset = DateCellChangeset;
  type CellProtobufType = DateCellDataPB;
  type CellFilter = DateFilterPB;
}

impl From<TypeOptionData> for DateTypeOption {
  fn from(data: TypeOptionData) -> Self {
    let date_format = data
      .get_i64_value("date_format")
      .map(DateFormat::from)
      .unwrap_or_default();
    let time_format = data
      .get_i64_value("time_format")
      .map(TimeFormat::from)
      .unwrap_or_default();
    let timezone_id = data.get_str_value("timezone_id").unwrap_or_default();
    Self {
      date_format,
      time_format,
      timezone_id,
    }
  }
}

impl From<DateTypeOption> for TypeOptionData {
  fn from(data: DateTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_i64_value("date_format", data.date_format.value())
      .insert_i64_value("time_format", data.time_format.value())
      .insert_str_value("timezone_id", data.timezone_id)
      .build()
  }
}

impl TypeOptionCellDataSerde for DateTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let timestamp = cell_data.timestamp;
    let include_time = cell_data.include_time;
    let (date, time) = self.formatted_date_time_from_timestamp(&timestamp);

    DateCellDataPB {
      date,
      time,
      timestamp: timestamp.unwrap_or_default(),
      include_time,
    }
  }

  fn parse_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(DateCellData::from(cell))
  }
}

impl DateTypeOption {
  pub fn new() -> Self {
    Self::default()
  }

  pub fn test() -> Self {
    Self {
      timezone_id: "Etc/UTC".to_owned(),
      ..Self::default()
    }
  }

  fn formatted_date_time_from_timestamp(&self, timestamp: &Option<i64>) -> (String, String) {
    if let Some(timestamp) = timestamp {
      let naive = chrono::NaiveDateTime::from_timestamp_opt(*timestamp, 0).unwrap();
      let offset = self.get_timezone_offset(naive);
      let date_time = DateTime::<Local>::from_utc(naive, offset);

      let fmt = self.date_format.format_str();
      let date = format!("{}", date_time.format(fmt));
      let fmt = self.time_format.format_str();
      let time = format!("{}", date_time.format(fmt));
      (date, time)
    } else {
      ("".to_owned(), "".to_owned())
    }
  }

  fn naive_time_from_time_string(
    &self,
    include_time: bool,
    time_str: Option<String>,
  ) -> FlowyResult<Option<NaiveTime>> {
    match (include_time, time_str) {
      (true, Some(time_str)) => {
        let result = NaiveTime::parse_from_str(&time_str, self.time_format.format_str());
        match result {
          Ok(time) => Ok(Some(time)),
          Err(_e) => {
            let msg = format!("Parse {} failed", time_str);
            Err(FlowyError::new(ErrorCode::InvalidDateTimeFormat, msg))
          },
        }
      },
      _ => Ok(None),
    }
  }

  fn timestamp_from_parsed_time_previous_and_new_timestamp(
    &self,
    parsed_time: Option<NaiveTime>,
    previous_timestamp: Option<i64>,
    changeset_timestamp: Option<i64>,
  ) -> Option<i64> {
    if let Some(time) = parsed_time {
      // a valid time is provided, so we replace the time component of old
      // (or new timestamp if provided) with it.
      let utc_date = changeset_timestamp
        .or(previous_timestamp)
        .map(|timestamp| NaiveDateTime::from_timestamp_opt(timestamp, 0).unwrap())
        .unwrap();
      let offset = self.get_timezone_offset(utc_date);

      let local_date = changeset_timestamp.or(previous_timestamp).map(|timestamp| {
        offset
          .from_utc_datetime(&NaiveDateTime::from_timestamp_opt(timestamp, 0).unwrap())
          .date_naive()
      });

      match local_date {
        Some(date) => {
          let local_datetime = offset
            .from_local_datetime(&NaiveDateTime::new(date, time))
            .unwrap();

          Some(local_datetime.timestamp())
        },
        None => None,
      }
    } else {
      changeset_timestamp.or(previous_timestamp)
    }
  }

  /// returns offset of Tz timezone if provided or of the local timezone otherwise
  fn get_timezone_offset(&self, date_time: NaiveDateTime) -> FixedOffset {
    let current_timezone_offset = Local::now().offset().fix();
    if self.timezone_id.is_empty() {
      current_timezone_offset
    } else {
      match Tz::from_str(&self.timezone_id) {
        Ok(timezone) => timezone.offset_from_utc_datetime(&date_time).fix(),
        Err(_) => current_timezone_offset,
      }
    }
  }
}

impl TypeOptionTransform for DateTypeOption {}

impl CellDataDecoder for DateTypeOption {
  fn decode_cell(
    &self,
    cell: &Cell,
    decoded_field_type: &FieldType,
    _field: &Field,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    // Return default data if the type_option_cell_data is not FieldType::DateTime.
    // It happens when switching from one field to another.
    // For example:
    // FieldType::RichText -> FieldType::DateTime, it will display empty content on the screen.
    if !decoded_field_type.is_date() {
      return Ok(Default::default());
    }

    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    let timestamp = cell_data.timestamp;
    let include_time = cell_data.include_time;
    let (date_string, time_string) = self.formatted_date_time_from_timestamp(&timestamp);
    if include_time && timestamp.is_some() {
      format!("{} {}", date_string, time_string)
    } else {
      date_string
    }
  }

  fn stringify_cell(&self, cell: &Cell) -> String {
    let cell_data = Self::CellData::from(cell);
    self.stringify_cell_data(cell_data)
  }
}

impl CellDataChangeset for DateTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    // old date cell data
    let (previous_timestamp, include_time) = match cell {
      Some(cell) => {
        let cell_data = DateCellData::from(&cell);
        (cell_data.timestamp, cell_data.include_time)
      },
      None => (None, false),
    };

    if changeset.clear_flag == Some(true) {
      let cell_data = DateCellData {
        timestamp: None,
        include_time,
      };

      return Ok((Cell::from(&cell_data), cell_data));
    }

    // update include_time if necessary
    let include_time = changeset.include_time.unwrap_or(include_time);

    // Calculate the timestamp in the time zone specified in type option. If
    // a new timestamp is included in the changeset without an accompanying
    // time string, the old timestamp will simply be overwritten. Meaning, in
    // order to change the day without changing the time, the old time string
    // should be passed in as well.

    let parsed_time = self.naive_time_from_time_string(include_time, changeset.time)?;

    let timestamp = self.timestamp_from_parsed_time_previous_and_new_timestamp(
      parsed_time,
      previous_timestamp,
      changeset.date,
    );

    let cell_data = DateCellData {
      timestamp,
      include_time,
    };

    Ok((Cell::from(&cell_data), cell_data))
  }
}

impl TypeOptionCellDataFilter for DateTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    field_type: &FieldType,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    if !field_type.is_date() {
      return true;
    }

    filter.is_visible(cell_data.timestamp)
  }
}

impl TypeOptionCellDataCompare for DateTypeOption {
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
