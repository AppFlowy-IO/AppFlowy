use crate::entities::{DateCellDataPB, DateFilterPB, FieldType};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, DateCellChangeset, DateCellData, DateCellDataWrapper, DateFormat, TimeFormat,
  TypeOption, TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter,
  TypeOptionTransform,
};
use chrono::format::strftime::StrftimeItems;
use chrono::{DateTime, Local, NaiveDateTime, NaiveTime, Offset, TimeZone};
use chrono_tz::{Tz, UTC};
use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::str::FromStr;

/// The [DateTypeOption] is used by [FieldType::Date], [FieldType::UpdatedAt], and [FieldType::CreatedAt].
/// So, storing the field type is necessary to distinguish the field type.
/// Most of the cases, each [FieldType] has its own [TypeOption] implementation.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DateTypeOption {
  pub date_format: DateFormat,
  pub time_format: TimeFormat,
  pub field_type: FieldType,
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
      .get_i64_value("data_format")
      .map(DateFormat::from)
      .unwrap_or_default();
    let time_format = data
      .get_i64_value("time_format")
      .map(TimeFormat::from)
      .unwrap_or_default();
    let field_type = data
      .get_i64_value("field_type")
      .map(FieldType::from)
      .unwrap_or(FieldType::DateTime);
    Self {
      date_format,
      time_format,
      field_type,
    }
  }
}

impl From<DateTypeOption> for TypeOptionData {
  fn from(data: DateTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_i64_value("data_format", data.date_format.value())
      .insert_i64_value("time_format", data.time_format.value())
      .insert_i64_value("field_type", data.field_type.value())
      .build()
  }
}

impl TypeOptionCellData for DateTypeOption {
  fn convert_to_protobuf(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    self.today_desc_from_timestamp(cell_data)
  }

  fn decode_cell(&self, cell: &Cell) -> FlowyResult<<Self as TypeOption>::CellData> {
    Ok(DateCellData::from(cell))
  }
}

impl DateTypeOption {
  pub fn new(field_type: FieldType) -> Self {
    Self {
      date_format: Default::default(),
      time_format: Default::default(),
      field_type,
    }
  }

  fn today_desc_from_timestamp(&self, cell_data: DateCellData) -> DateCellDataPB {
    let timestamp = cell_data.timestamp.unwrap_or_default();
    let include_time = cell_data.include_time;
    let timezone_id = cell_data.timezone_id;

    let (date, time) = match cell_data.timestamp {
      Some(timestamp) => {
        let naive = chrono::NaiveDateTime::from_timestamp_opt(timestamp, 0).unwrap();
        let offset = match Tz::from_str(&timezone_id) {
          Ok(timezone) => timezone.offset_from_utc_datetime(&naive).fix(),
          Err(_) => *Local::now().offset(),
        };

        let date_time = DateTime::<Local>::from_utc(naive, offset);

        let fmt = self.date_format.format_str();
        let date = format!("{}", date_time.format_with_items(StrftimeItems::new(fmt)));
        let fmt = self.time_format.format_str();
        let time = format!("{}", date_time.format_with_items(StrftimeItems::new(fmt)));

        (date, time)
      },
      None => ("".to_owned(), "".to_owned()),
    };

    DateCellDataPB {
      date,
      time,
      include_time,
      timestamp,
      timezone_id,
    }
  }

  fn timestamp_from_parsed_time_previous_and_new_timestamp(
    &self,
    timezone: Tz,
    parsed_time: Option<NaiveTime>,
    previous_timestamp: Option<i64>,
    changeset_timestamp: Option<i64>,
  ) -> Option<i64> {
    if let Some(time) = parsed_time {
      // a valid time is provided, so we replace the time component of old
      // (or new timestamp if provided) with it.
      let local_date = changeset_timestamp.or(previous_timestamp).map(|timestamp| {
        timezone
          .from_utc_datetime(&NaiveDateTime::from_timestamp_opt(timestamp, 0).unwrap())
          .date_naive()
      });

      match local_date {
        Some(date) => {
          let local_datetime = timezone
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
}

impl TypeOptionTransform for DateTypeOption {}

impl CellDataDecoder for DateTypeOption {
  fn decode_cell_str(
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

    self.decode_cell(cell)
  }

  fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    self.today_desc_from_timestamp(cell_data).date
  }

  fn decode_cell_to_str(&self, cell: &Cell) -> String {
    let cell_data = Self::CellData::from(cell);
    self.decode_cell_data_to_str(cell_data)
  }
}

impl CellDataChangeset for DateTypeOption {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    cell: Option<Cell>,
  ) -> FlowyResult<(Cell, <Self as TypeOption>::CellData)> {
    // old date cell data
    let (previous_timestamp, include_time, timezone_id) = match cell {
      None => (None, false, "".to_owned()),
      Some(cell) => {
        let cell_data = DateCellData::from(&cell);
        (
          cell_data.timestamp,
          cell_data.include_time,
          cell_data.timezone_id,
        )
      },
    };

    // update include_time and timezone_id if necessary
    let include_time = changeset.include_time.unwrap_or(include_time);
    let timezone_id = changeset
      .timezone_id
      .as_ref()
      .map(|timezone_id| timezone_id.to_owned())
      .unwrap_or_else(|| timezone_id);

    // Calculate the timezone-aware timestamp. If a new timestamp is included
    // in the changeset without an accompanying time string, the old timestamp
    // will simply be overwritten. Meaning, in order to change the day without
    // changing the time, the old time string should be passed in as well.
    let changeset_timestamp = changeset.date_timestamp();

    // parse the time string, which is in the timezone corresponding to
    // timezone_id or local
    let parsed_time = match (include_time, changeset.time) {
      (true, Some(time_str)) => {
        let result = NaiveTime::parse_from_str(&time_str, self.time_format.format_str());
        match result {
          Ok(time) => Ok(Some(time)),
          Err(_e) => {
            let msg = format!("Parse {} failed", time_str);
            Err(FlowyError::new(ErrorCode::InvalidDateTimeFormat, &msg))
          },
        }
      },
      _ => Ok(None),
    }?;

    // Tz timezone if provided, local timezone otherwise
    let current_timezone_offset = UTC
      .offset_from_local_datetime(&Local::now().naive_local())
      .unwrap();
    let current_timezone = Tz::from_offset(&current_timezone_offset);
    let timezone = if timezone_id.is_empty() {
      current_timezone
    } else {
      match Tz::from_str(&timezone_id) {
        Ok(timezone) => timezone,
        Err(_) => current_timezone,
      }
    };

    let timestamp = self.timestamp_from_parsed_time_previous_and_new_timestamp(
      timezone,
      parsed_time,
      previous_timestamp,
      changeset_timestamp,
    );

    let cell_data = DateCellData {
      timestamp,
      include_time,
      timezone_id,
    };

    let cell_wrapper: DateCellDataWrapper = (self.field_type.clone(), cell_data.clone()).into();
    Ok((Cell::from(cell_wrapper), cell_data))
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
  ) -> Ordering {
    match (cell_data.timestamp, other_cell_data.timestamp) {
      (Some(left), Some(right)) => left.cmp(&right),
      (Some(_), None) => Ordering::Greater,
      (None, Some(_)) => Ordering::Less,
      (None, None) => default_order(),
    }
  }
}
