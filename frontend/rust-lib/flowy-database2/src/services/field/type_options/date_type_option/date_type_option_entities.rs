#![allow(clippy::upper_case_acronyms)]

use bytes::Bytes;
use collab::core::any_map::AnyMapExtension;
use collab_database::rows::{new_cell_builder, Cell};
use serde::de::Visitor;
use serde::{Deserialize, Serialize};
use std::fmt;
use strum_macros::EnumIter;

use flowy_error::{internal_error, FlowyResult};

use crate::entities::{DateCellDataPB, FieldType};
use crate::services::cell::{
  CellProtobufBlobParser, DecodedCellData, FromCellChangeset, FromCellString, ToCellChangeset,
};
use crate::services::field::{TypeOptionCellData, CELL_DATA};

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct DateCellChangeset {
  pub date: Option<i64>,
  pub time: Option<String>,
  pub include_time: Option<bool>,
  pub clear_flag: Option<bool>,
}

impl FromCellChangeset for DateCellChangeset {
  fn from_changeset(changeset: String) -> FlowyResult<Self>
  where
    Self: Sized,
  {
    serde_json::from_str::<DateCellChangeset>(&changeset).map_err(internal_error)
  }
}

impl ToCellChangeset for DateCellChangeset {
  fn to_cell_changeset_str(&self) -> String {
    serde_json::to_string(self).unwrap_or_default()
  }
}

#[derive(Default, Clone, Debug, Serialize)]
pub struct DateCellData {
  pub timestamp: Option<i64>,
  #[serde(default)]
  pub include_time: bool,
}

impl DateCellData {
  pub fn new(timestamp: i64, include_time: bool) -> Self {
    Self {
      timestamp: Some(timestamp),
      include_time,
    }
  }
}

impl TypeOptionCellData for DateCellData {
  fn is_cell_empty(&self) -> bool {
    self.timestamp.is_none()
  }
}

impl From<&Cell> for DateCellData {
  fn from(cell: &Cell) -> Self {
    let timestamp = cell
      .get_str_value(CELL_DATA)
      .and_then(|data| data.parse::<i64>().ok());
    let include_time = cell.get_bool_value("include_time").unwrap_or_default();
    Self {
      timestamp,
      include_time,
    }
  }
}

impl From<&DateCellDataPB> for DateCellData {
  fn from(data: &DateCellDataPB) -> Self {
    Self {
      timestamp: Some(data.timestamp),
      include_time: data.include_time,
    }
  }
}

impl From<&DateCellData> for Cell {
  fn from(cell_data: &DateCellData) -> Self {
    let timestamp_string = match cell_data.timestamp {
      Some(timestamp) => timestamp.to_string(),
      None => "".to_owned(),
    };
    new_cell_builder(FieldType::DateTime)
      .insert_str_value(CELL_DATA, timestamp_string)
      .insert_bool_value("include_time", cell_data.include_time)
      .build()
  }
}

impl<'de> serde::Deserialize<'de> for DateCellData {
  fn deserialize<D>(deserializer: D) -> core::result::Result<Self, D::Error>
  where
    D: serde::Deserializer<'de>,
  {
    struct DateCellVisitor();

    impl<'de> Visitor<'de> for DateCellVisitor {
      type Value = DateCellData;

      fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str(
          "DateCellData with type: str containing either an integer timestamp or the JSON representation",
        )
      }

      fn visit_i64<E>(self, value: i64) -> Result<Self::Value, E>
      where
        E: serde::de::Error,
      {
        Ok(DateCellData {
          timestamp: Some(value),
          include_time: false,
        })
      }

      fn visit_u64<E>(self, value: u64) -> Result<Self::Value, E>
      where
        E: serde::de::Error,
      {
        self.visit_i64(value as i64)
      }

      fn visit_map<M>(self, mut map: M) -> Result<Self::Value, M::Error>
      where
        M: serde::de::MapAccess<'de>,
      {
        let mut timestamp: Option<i64> = None;
        let mut include_time: Option<bool> = None;

        while let Some(key) = map.next_key()? {
          match key {
            "timestamp" => {
              timestamp = map.next_value()?;
            },
            "include_time" => {
              include_time = map.next_value()?;
            },
            _ => {},
          }
        }

        let include_time = include_time.unwrap_or_default();

        Ok(DateCellData {
          timestamp,
          include_time,
        })
      }
    }

    deserializer.deserialize_any(DateCellVisitor())
  }
}

impl FromCellString for DateCellData {
  fn from_cell_str(s: &str) -> FlowyResult<Self>
  where
    Self: Sized,
  {
    let result: DateCellData = serde_json::from_str(s).unwrap();
    Ok(result)
  }
}

impl ToString for DateCellData {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}

#[derive(Clone, Debug, Copy, EnumIter, Serialize, Deserialize, Default)]
pub enum DateFormat {
  Local = 0,
  US = 1,
  ISO = 2,
  #[default]
  Friendly = 3,
  DayMonthYear = 4,
}

impl std::convert::From<i64> for DateFormat {
  fn from(value: i64) -> Self {
    match value {
      0 => DateFormat::Local,
      1 => DateFormat::US,
      2 => DateFormat::ISO,
      3 => DateFormat::Friendly,
      4 => DateFormat::DayMonthYear,
      _ => {
        tracing::error!("Unsupported date format, fallback to friendly");
        DateFormat::Friendly
      },
    }
  }
}

impl DateFormat {
  pub fn value(&self) -> i64 {
    *self as i64
  }
  // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
  pub fn format_str(&self) -> &'static str {
    match self {
      DateFormat::Local => "%m/%d/%Y",
      DateFormat::US => "%Y/%m/%d",
      DateFormat::ISO => "%Y-%m-%d",
      DateFormat::Friendly => "%b %d, %Y",
      DateFormat::DayMonthYear => "%d/%m/%Y",
    }
  }
}

#[derive(Clone, Copy, PartialEq, Eq, EnumIter, Debug, Hash, Serialize, Deserialize, Default)]
pub enum TimeFormat {
  TwelveHour = 0,
  #[default]
  TwentyFourHour = 1,
}

impl std::convert::From<i64> for TimeFormat {
  fn from(value: i64) -> Self {
    match value {
      0 => TimeFormat::TwelveHour,
      1 => TimeFormat::TwentyFourHour,
      _ => {
        tracing::error!("Unsupported time format, fallback to TwentyFourHour");
        TimeFormat::TwentyFourHour
      },
    }
  }
}

impl TimeFormat {
  pub fn value(&self) -> i64 {
    *self as i64
  }

  // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
  pub fn format_str(&self) -> &'static str {
    match self {
      TimeFormat::TwelveHour => "%I:%M %p",
      TimeFormat::TwentyFourHour => "%R",
    }
  }
}

impl DecodedCellData for DateCellDataPB {
  type Object = DateCellDataPB;

  fn is_empty(&self) -> bool {
    self.date.is_empty()
  }
}

pub struct DateCellDataParser();
impl CellProtobufBlobParser for DateCellDataParser {
  type Object = DateCellDataPB;

  fn parser(bytes: &Bytes) -> FlowyResult<Self::Object> {
    DateCellDataPB::try_from(bytes.as_ref()).map_err(internal_error)
  }
}
