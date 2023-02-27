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
use chrono::{NaiveDateTime, Timelike};
use database_model::{FieldRevision, TypeOptionDataDeserializer, TypeOptionDataSerializer};
use flowy_derive::ProtoBuf;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

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

  fn today_desc_from_timestamp<T: Into<i64>>(&self, timestamp: T) -> DateCellDataPB {
    let timestamp = timestamp.into();
    let native = chrono::NaiveDateTime::from_timestamp_opt(timestamp, 0);
    if native.is_none() {
      return DateCellDataPB::default();
    }
    let native = native.unwrap();
    if native.timestamp() == 0 {
      return DateCellDataPB::default();
    }

    let time = native.time();
    let has_time = time.hour() != 0 || time.second() != 0;

    let utc = self.utc_date_time_from_native(native);
    let fmt = self.date_format.format_str();
    let date = format!("{}", utc.format_with_items(StrftimeItems::new(fmt)));

    let mut time = "".to_string();
    if has_time && self.include_time {
      let fmt = format!(
        "{}{}",
        self.date_format.format_str(),
        self.time_format.format_str()
      );
      time = format!("{}", utc.format_with_items(StrftimeItems::new(&fmt))).replace(&date, "");
    }

    let timestamp = native.timestamp();
    DateCellDataPB {
      date,
      time,
      timestamp,
    }
  }

  fn date_fmt(&self, time: &Option<String>) -> String {
    if self.include_time {
      match time.as_ref() {
        None => self.date_format.format_str().to_string(),
        Some(time_str) => {
          if time_str.is_empty() {
            self.date_format.format_str().to_string()
          } else {
            format!(
              "{} {}",
              self.date_format.format_str(),
              self.time_format.format_str()
            )
          }
        },
      }
    } else {
      self.date_format.format_str().to_string()
    }
  }

  fn timestamp_from_utc_with_time(
    &self,
    utc: &chrono::DateTime<chrono::Utc>,
    time: &Option<String>,
  ) -> FlowyResult<i64> {
    if let Some(time_str) = time.as_ref() {
      if !time_str.is_empty() {
        let date_str = format!(
          "{}{}",
          utc.format_with_items(StrftimeItems::new(self.date_format.format_str())),
          &time_str
        );

        return match NaiveDateTime::parse_from_str(&date_str, &self.date_fmt(time)) {
          Ok(native) => {
            let utc = self.utc_date_time_from_native(native);
            Ok(utc.timestamp())
          },
          Err(_e) => {
            let msg = format!("Parse {} failed", date_str);
            Err(FlowyError::new(ErrorCode::InvalidDateTimeFormat, &msg))
          },
        };
      }
    }

    Ok(utc.timestamp())
  }

  fn utc_date_time_from_native(
    &self,
    naive: chrono::NaiveDateTime,
  ) -> chrono::DateTime<chrono::Utc> {
    chrono::DateTime::<chrono::Utc>::from_utc(naive, chrono::Utc)
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
    _type_cell_data: Option<TypeCellData>,
  ) -> FlowyResult<(String, <Self as TypeOption>::CellData)> {
    let cell_data = match changeset.date_timestamp() {
      None => 0,
      Some(date_timestamp) => match (self.include_time, changeset.time) {
        (true, Some(time)) => {
          let time = Some(time.trim().to_uppercase());
          let native = NaiveDateTime::from_timestamp_opt(date_timestamp, 0);
          if let Some(native) = native {
            let utc = self.utc_date_time_from_native(native);
            self.timestamp_from_utc_with_time(&utc, &time)?
          } else {
            date_timestamp
          }
        },
        _ => date_timestamp,
      },
    };
    let date_cell_data = DateCellData(Some(cell_data));
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

    filter.is_visible(cell_data.0)
  }
}

impl TypeOptionCellDataCompare for DateTypeOptionPB {
  fn apply_cmp(
    &self,
    cell_data: &<Self as TypeOption>::CellData,
    other_cell_data: &<Self as TypeOption>::CellData,
  ) -> Ordering {
    match (cell_data.0, other_cell_data.0) {
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
