use crate::entities::{DateFilterPB, FieldType};
use crate::impl_type_option;
use crate::services::cell::{CellDataChangeset, CellDataDecoder, FromCellString, TypeCellData};
use crate::services::field::{
  default_order, BoxTypeOptionBuilder, DateCellChangeset, DateCellData, DateCellDataPB, DateFormat,
  TimeFormat, TypeOption, TypeOptionBuilder, TypeOptionCellData, TypeOptionCellDataCompare,
  TypeOptionCellDataFilter, TypeOptionTransform,
};
use bytes::Bytes;
use chrono::format::strftime::StrftimeItems;
use chrono::{DateTime, Local, NaiveDateTime, NaiveTime, Offset, TimeZone};
use chrono_tz::Tz;
use database_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use flowy_derive::ProtoBuf;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::str::FromStr;

// Date
#[derive(Clone, Debug, Default, Serialize, Deserialize, ProtoBuf)]
pub struct DateTypeOptionPB {
  #[pb(index = 1)]
  pub date_format: DateFormat,

  #[pb(index = 2)]
  pub time_format: TimeFormat,

  #[pb(index = 3)]
  pub include_time: bool,
}
impl_type_option!(DateTypeOptionPB, FieldType::DateTime);

impl TypeOption for DateTypeOptionPB {
  type CellData = DateCellData;
  type CellChangeset = DateCellChangeset;
  type CellProtobufType = DateCellDataPB;
  type CellFilter = DateFilterPB;
}

impl TypeOptionCellData for DateTypeOptionPB {
  fn convert_to_protobuf(
    &self,
    cell_data: <Self as TypeOption>::CellData,
  ) -> <Self as TypeOption>::CellProtobufType {
    self.today_desc_from_timestamp(cell_data)
  }

  fn decode_type_option_cell_str(
    &self,
    cell_str: String,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    DateCellData::from_cell_str(&cell_str)
  }
}

impl DateTypeOptionPB {
  #[allow(dead_code)]
  pub fn new() -> Self {
    Self::default()
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
          Err(_) => Local::now().offset().clone(),
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
}

impl TypeOptionTransform for DateTypeOptionPB {}

impl CellDataDecoder for DateTypeOptionPB {
  fn decode_cell_str(
    &self,
    cell_str: String,
    decoded_field_type: &FieldType,
    _field_rev: &FieldRevision,
  ) -> FlowyResult<<Self as TypeOption>::CellData> {
    // Return default data if the type_option_cell_data is not FieldType::DateTime.
    // It happens when switching from one field to another.
    // For example:
    // FieldType::RichText -> FieldType::DateTime, it will display empty content on the screen.
    if !decoded_field_type.is_date() {
      return Ok(Default::default());
    }

    self.decode_type_option_cell_str(cell_str)
  }

  fn decode_cell_data_to_str(&self, cell_data: <Self as TypeOption>::CellData) -> String {
    self.today_desc_from_timestamp(cell_data).date
  }
}

impl CellDataChangeset for DateTypeOptionPB {
  fn apply_changeset(
    &self,
    changeset: <Self as TypeOption>::CellChangeset,
    type_cell_data: Option<TypeCellData>,
  ) -> FlowyResult<(String, <Self as TypeOption>::CellData)> {
    // old date cell data
    let (timestamp, include_time, timezone_id) = match type_cell_data {
      None => (None, false, "".to_owned()),
      Some(type_cell_data) => {
        let cell_data = DateCellData::from_cell_str(&type_cell_data.cell_str).unwrap_or_default();
        (
          cell_data.timestamp,
          cell_data.include_time,
          cell_data.timezone_id,
        )
      },
    };

    // update include_time and timezone_id if present
    let include_time = match changeset.include_time {
      None => include_time,
      Some(include_time) => include_time,
    };
    let timezone_id = match changeset.timezone_id {
      None => timezone_id,
      Some(ref timezone_id) => timezone_id.to_owned(),
    };

    let previous_datetime = match timestamp {
      Some(timestamp) => NaiveDateTime::from_timestamp_opt(timestamp, 0),
      None => None,
    };

    let new_date_timestamp = changeset.date_timestamp();

    // parse the time string, which would be in the local timezone
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

    // Calculate the new timestamp, while keeping in mind the timezone.
    // If a new timestamp is included in the changeset without an accompanying
    // time string, the new timestamp will simply overwrite the old one. This
    // means that in order to change the day without time in the frontend,
    // the time string must also be passed. This removes confusion over
    // unfavorable situations where the time component of a new timestamp gets
    // removed.
    let timestamp = match Tz::from_str(&timezone_id) {
      Ok(timezone) => match parsed_time {
        Some(time) => {
          // a valid time is provided, so we can replace the time component of old or new timestamp with this.
          let local_date = match new_date_timestamp {
            Some(timestamp) => Some(
              timezone
                .from_utc_datetime(&NaiveDateTime::from_timestamp_opt(timestamp, 0).unwrap())
                .date_naive(),
            ),
            None => match previous_datetime {
              Some(datetime) => Some(timezone.from_utc_datetime(&datetime).date_naive()),
              None => None,
            },
          };

          match local_date {
            Some(date) => {
              let local_datetime = NaiveDateTime::new(date, time);
              let datetime = timezone.from_local_datetime(&local_datetime).unwrap();

              Some(datetime.timestamp())
            },
            None => None,
          }
        },
        None => match new_date_timestamp {
          Some(timestamp) => Some(timestamp),
          None => timestamp,
        },
      },
      Err(_) => match parsed_time {
        Some(time) => {
          let offset = Local::now().offset().clone();

          let local_date = match new_date_timestamp {
            Some(timestamp) => Some(
              offset
                .from_utc_datetime(&NaiveDateTime::from_timestamp_opt(timestamp, 0).unwrap())
                .date_naive(),
            ),
            None => match previous_datetime {
              Some(datetime) => Some(offset.from_utc_datetime(&datetime).date_naive()),
              None => None,
            },
          };

          match local_date {
            Some(date) => {
              let local_datetime = NaiveDateTime::new(date, time);
              let datetime = offset.from_local_datetime(&local_datetime).unwrap();

              Some(datetime.timestamp())
            },
            None => None,
          }
        },
        None => match new_date_timestamp {
          Some(timestamp) => Some(timestamp),
          None => timestamp,
        },
      },
    };

    let date_cell_data = DateCellData {
      timestamp,
      include_time,
      timezone_id,
    };
    Ok((date_cell_data.to_string(), date_cell_data))
  }
}

impl TypeOptionCellDataFilter for DateTypeOptionPB {
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

impl TypeOptionCellDataCompare for DateTypeOptionPB {
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

#[derive(Default)]
pub struct DateTypeOptionBuilder(DateTypeOptionPB);
impl_into_box_type_option_builder!(DateTypeOptionBuilder);
impl_builder_from_json_str_and_from_bytes!(DateTypeOptionBuilder, DateTypeOptionPB);

impl DateTypeOptionBuilder {
  pub fn date_format(mut self, date_format: DateFormat) -> Self {
    self.0.date_format = date_format;
    self
  }

  pub fn time_format(mut self, time_format: TimeFormat) -> Self {
    self.0.time_format = time_format;
    self
  }
}
impl TypeOptionBuilder for DateTypeOptionBuilder {
  fn field_type(&self) -> FieldType {
    FieldType::DateTime
  }

  fn serializer(&self) -> &dyn TypeOptionDataSerializer {
    &self.0
  }
}
