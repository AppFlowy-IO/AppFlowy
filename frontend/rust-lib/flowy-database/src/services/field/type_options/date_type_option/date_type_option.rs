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
use chrono::NaiveDateTime;
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

  fn today_desc_from_timestamp(&self, cell_data: DateCellData) -> DateCellDataPB {
    let timestamp = cell_data.timestamp.unwrap_or_default();
    let include_time = cell_data.include_time;

    let naive = chrono::NaiveDateTime::from_timestamp_opt(timestamp, 0);
    if naive.is_none() {
      return DateCellDataPB::default();
    }
    let naive = naive.unwrap();
    if timestamp == 0 {
      return DateCellDataPB::default();
    }
    let fmt = self.date_format.format_str();
    let date = format!("{}", naive.format_with_items(StrftimeItems::new(fmt)));

    let time = if include_time {
      let fmt = self.time_format.format_str();
      format!("{}", naive.format_with_items(StrftimeItems::new(fmt)))
    } else {
      "".to_string()
    };

    DateCellDataPB {
      date,
      time,
      include_time,
      timestamp,
    }
  }

  fn timestamp_from_utc_with_time(
    &self,
    naive_date: &NaiveDateTime,
    time_str: &Option<String>,
  ) -> FlowyResult<i64> {
    if let Some(time_str) = time_str.as_ref() {
      if !time_str.is_empty() {
        let naive_time = chrono::NaiveTime::parse_from_str(time_str, self.time_format.format_str());

        match naive_time {
          Ok(naive_time) => {
            return Ok(naive_date.date().and_time(naive_time).timestamp());
          },
          Err(_e) => {
            let msg = format!("Parse {} failed", time_str);
            return Err(FlowyError::new(ErrorCode::InvalidDateTimeFormat, &msg));
          },
        };
      }
    }

    Ok(naive_date.timestamp())
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
    let (timestamp, include_time) = match type_cell_data {
      None => (None, false),
      Some(type_cell_data) => {
        let cell_data = DateCellData::from_cell_str(&type_cell_data.cell_str).unwrap_or_default();
        (cell_data.timestamp, cell_data.include_time)
      },
    };

    let include_time = match changeset.include_time {
      None => include_time,
      Some(include_time) => include_time,
    };
    let timestamp = match changeset.date_timestamp() {
      None => timestamp,
      Some(date_timestamp) => match (include_time, changeset.time) {
        (true, Some(time)) => {
          let time = Some(time.trim().to_uppercase());
          let naive = NaiveDateTime::from_timestamp_opt(date_timestamp, 0);
          if let Some(naive) = naive {
            Some(self.timestamp_from_utc_with_time(&naive, &time)?)
          } else {
            Some(date_timestamp)
          }
        },
        _ => Some(date_timestamp),
      },
    };

    let date_cell_data = DateCellData {
      timestamp,
      include_time,
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
