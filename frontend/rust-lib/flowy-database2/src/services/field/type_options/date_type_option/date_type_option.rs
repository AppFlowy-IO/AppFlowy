use crate::entities::{DateCellDataPB, DateFilterPB, FieldType};
use crate::services::cell::{CellDataChangeset, CellDataDecoder};
use crate::services::field::{
  default_order, DateCellChangeset, DateCellData, DateFormat, TimeFormat, TypeOption,
  TypeOptionCellData, TypeOptionCellDataCompare, TypeOptionCellDataFilter, TypeOptionTransform,
};

use chrono::format::strftime::StrftimeItems;
use chrono::NaiveDateTime;

use collab::core::any_map::AnyMapExtension;
use collab_database::fields::{Field, TypeOptionData, TypeOptionDataBuilder};
use collab_database::rows::Cell;
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

// Date
#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct DateTypeOption {
  pub date_format: DateFormat,
  pub time_format: TimeFormat,
  pub include_time: bool,
}

impl TypeOption for DateTypeOption {
  type CellData = DateCellData;
  type CellChangeset = DateCellChangeset;
  type CellProtobufType = DateCellDataPB;
  type CellFilter = DateFilterPB;
}

impl From<TypeOptionData> for DateTypeOption {
  fn from(data: TypeOptionData) -> Self {
    let include_time = data.get_bool_value("include_time").unwrap_or(false);
    let date_format = data
      .get_i64_value("data_format")
      .map(DateFormat::from)
      .unwrap_or_default();
    let time_format = data
      .get_i64_value("time_format")
      .map(TimeFormat::from)
      .unwrap_or_default();
    Self {
      date_format,
      time_format,
      include_time,
    }
  }
}

impl From<DateTypeOption> for TypeOptionData {
  fn from(data: DateTypeOption) -> Self {
    TypeOptionDataBuilder::new()
      .insert_i64_value("data_format", data.date_format.value())
      .insert_i64_value("time_format", data.time_format.value())
      .insert_bool_value("include_time", data.include_time)
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
    let (timestamp, include_time) = match cell {
      None => (None, false),
      Some(cell) => {
        let cell_data = DateCellData::from(&cell);
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
    Ok((date_cell_data.clone().into(), date_cell_data))
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
