use async_trait::async_trait;
use chrono::{DateTime, FixedOffset, Local, NaiveDateTime, NaiveTime, Offset, TimeZone};
use chrono_tz::Tz;
use collab::preclude::Any;
use collab::util::AnyMapExt;
use collab_database::database::Database;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use collab_database::template::date_parse::cast_string_to_timestamp;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::str::FromStr;
use tracing::info;

use crate::entities::{DateCellDataPB, DateFilterPB, FieldType};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, DateCellChangeset, DateCellData, DateFormat, TimeFormat, TypeOption,
  TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionCellDataSerde,
  TypeOptionTransform, CELL_DATA,
};
use crate::services::sort::SortCondition;

#[derive(Clone, Debug, Serialize, Deserialize, Default)]
pub struct DateTypeOption {
  pub date_format: DateFormat,
  pub time_format: TimeFormat,
  pub timezone_id: String,
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
      .get_as::<i64>("date_format")
      .map(DateFormat::from)
      .unwrap_or_default();
    let time_format = data
      .get_as::<i64>("time_format")
      .map(TimeFormat::from)
      .unwrap_or_default();
    let timezone_id: String = data.get_as("timezone_id").unwrap_or_default();
    Self {
      date_format,
      time_format,
      timezone_id,
    }
  }
}

impl From<DateTypeOption> for TypeOptionData {
  fn from(data: DateTypeOption) -> Self {
    TypeOptionDataBuilder::from([
      ("date_format".into(), Any::BigInt(data.date_format.value())),
      ("time_format".into(), Any::BigInt(data.time_format.value())),
      ("timezone_id".into(), data.timezone_id.into()),
    ])
  }
}

impl TypeOptionCellDataSerde for DateTypeOption {
  fn protobuf_encode(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    let include_time = cell_data.include_time;
    let is_range = cell_data.is_range;

    let timestamp = cell_data.timestamp;
    let (date, time) = self.formatted_date_time_from_timestamp(&timestamp);

    let end_timestamp = cell_data.end_timestamp;
    let (end_date, end_time) = self.formatted_date_time_from_timestamp(&end_timestamp);

    let reminder_id = cell_data.reminder_id;

    DateCellDataPB {
      date,
      time,
      timestamp: timestamp.unwrap_or_default(),
      end_date,
      end_time,
      end_timestamp: end_timestamp.unwrap_or_default(),
      include_time,
      is_range,
      reminder_id,
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

  /// combine the changeset_timestamp and parsed_time if provided. if
  /// changeset_timestamp is None, fallback to previous_timestamp
  fn timestamp_from_parsed_time_previous_and_new_timestamp(
    &self,
    parsed_time: Option<NaiveTime>,
    previous_timestamp: Option<i64>,
    changeset_timestamp: Option<i64>,
  ) -> Option<i64> {
    if let Some(time) = parsed_time {
      // a valid time is provided, so we replace the time component of old timestamp
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

#[async_trait]
impl TypeOptionTransform for DateTypeOption {
  async fn transform_type_option(
    &mut self,
    view_id: &str,
    field_id: &str,
    old_type_option_field_type: FieldType,
    _old_type_option_data: TypeOptionData,
    _new_type_option_field_type: FieldType,
    database: &mut Database,
  ) {
    match old_type_option_field_type {
      FieldType::RichText => {
        let rows = database
          .get_cells_for_field(view_id, field_id)
          .await
          .into_iter()
          .filter_map(|row| row.cell.map(|cell| (row.row_id, cell)))
          .collect::<Vec<_>>();

        info!(
          "Transforming RichText to DateTypeOption, updating {} row's cell content",
          rows.len()
        );
        for (row_id, cell_data) in rows {
          if let Some(cell_data) = cell_data
            .get_as::<String>(CELL_DATA)
            .and_then(|s| cast_string_to_timestamp(&s))
            .map(DateCellData::from_timestamp)
          {
            database
              .update_row(row_id, |row| {
                row.update_cells(|cell| {
                  cell.insert(field_id, Cell::from(&cell_data));
                });
              })
              .await;
          }
        }
      },
      _ => {
        // do nothing
      },
    }
  }
}

impl CellDataDecoder for DateTypeOption {
  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    self.parse_cell(cell)
  }

  fn stringify_cell_data(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    let include_time = cell_data.include_time;
    let timestamp = cell_data.timestamp;
    let is_range = cell_data.is_range;

    let (date, time) = self.formatted_date_time_from_timestamp(&timestamp);

    if is_range {
      let (end_date, end_time) = match cell_data.end_timestamp {
        Some(timestamp) => self.formatted_date_time_from_timestamp(&Some(timestamp)),
        None => (date.clone(), time.clone()),
      };
      if include_time && timestamp.is_some() {
        format!("{} {} → {} {}", date, time, end_date, end_time)
          .trim()
          .to_string()
      } else if timestamp.is_some() {
        format!("{} → {}", date, end_date).trim().to_string()
      } else {
        "".to_string()
      }
    } else if include_time {
      format!("{} {}", date, time).trim().to_string()
    } else {
      date
    }
  }

  fn decode_cell_with_transform(
    &self,
    cell: &Cell,
    _from_field_type: FieldType,
    _field: &Field,
  ) -> Option<<Self as TypeOption>::CellData> {
    let s = cell.get_as::<String>(CELL_DATA)?;
    let timestamp = cast_string_to_timestamp(&s)?;
    Some(DateCellData::from_timestamp(timestamp))
  }

  fn numeric_cell(&self, _cell: &Cell) -> Option<f64> {
    None
  }
}

impl CellDataChangeset for DateTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    // old date cell data
    let (previous_timestamp, previous_end_timestamp, include_time, is_range, reminder_id) =
      match cell {
        Some(cell) => {
          let cell_data = DateCellData::from(&cell);
          (
            cell_data.timestamp,
            cell_data.end_timestamp,
            cell_data.include_time,
            cell_data.is_range,
            cell_data.reminder_id,
          )
        },
        None => (None, None, false, false, String::new()),
      };

    if changeset.clear_flag == Some(true) {
      let cell_data = DateCellData {
        timestamp: None,
        end_timestamp: None,
        include_time,
        is_range,
        reminder_id: String::new(),
      };

      return Ok((Cell::from(&cell_data), cell_data));
    }

    // update include_time and is_range if necessary
    let include_time = changeset.include_time.unwrap_or(include_time);
    let is_range = changeset.is_range.unwrap_or(is_range);
    let reminder_id = changeset.reminder_id.unwrap_or(reminder_id);

    // Calculate the timestamp in the time zone specified in type option. If
    // a new timestamp is included in the changeset without an accompanying
    // time string, the old timestamp will simply be overwritten. Meaning, in
    // order to change the day without changing the time, the old time string
    // should be passed in as well.

    // parse the time string, which is in the local timezone
    let parsed_start_time = self.naive_time_from_time_string(include_time, changeset.time)?;

    let timestamp = self.timestamp_from_parsed_time_previous_and_new_timestamp(
      parsed_start_time,
      previous_timestamp,
      changeset.date,
    );

    let end_timestamp =
      if is_range && changeset.end_date.is_none() && previous_end_timestamp.is_none() {
        // just toggled is_range so no passed in or existing end time data
        timestamp
      } else if is_range {
        // parse the changeset's end time data or fallback to previous version
        let parsed_end_time = self.naive_time_from_time_string(include_time, changeset.end_time)?;

        self.timestamp_from_parsed_time_previous_and_new_timestamp(
          parsed_end_time,
          previous_end_timestamp,
          changeset.end_date,
        )
      } else {
        // clear the end time data
        None
      };

    let cell_data = DateCellData {
      timestamp,
      end_timestamp,
      include_time,
      is_range,
      reminder_id,
    };

    Ok((Cell::from(&cell_data), cell_data))
  }
}

impl TypeOptionCellDataFilter for DateTypeOption {
  fn apply_filter(
    &self,
    filter: &<Self as TypeOption>::CellFilter,
    cell_data: &<Self as TypeOption>::CellData,
  ) -> bool {
    filter.is_visible(cell_data).unwrap_or(true)
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
