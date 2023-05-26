#![allow(clippy::upper_case_acronyms)]

use strum_macros::EnumIter;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

use crate::entities::{CellIdPB, FieldType};
use crate::services::field::{DateFormat, DateTypeOption, TimeFormat};

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateCellDataPB {
  #[pb(index = 1)]
  pub date: String,

  #[pb(index = 2)]
  pub time: String,

  #[pb(index = 3)]
  pub timestamp: i64,

  #[pb(index = 4)]
  pub include_time: bool,
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateChangesetPB {
  #[pb(index = 1)]
  pub cell_path: CellIdPB,

  #[pb(index = 2, one_of)]
  pub date: Option<String>,

  #[pb(index = 3, one_of)]
  pub time: Option<String>,

  #[pb(index = 4, one_of)]
  pub include_time: Option<bool>,
}

// Date
#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateTypeOptionPB {
  #[pb(index = 1)]
  pub date_format: DateFormatPB,

  #[pb(index = 2)]
  pub time_format: TimeFormatPB,

  #[pb(index = 3)]
  pub timezone_id: String,

  #[pb(index = 4)]
  pub field_type: FieldType,
}

impl From<DateTypeOption> for DateTypeOptionPB {
  fn from(data: DateTypeOption) -> Self {
    Self {
      date_format: data.date_format.into(),
      time_format: data.time_format.into(),
      timezone_id: data.timezone_id,
      field_type: data.field_type,
    }
  }
}

impl From<DateTypeOptionPB> for DateTypeOption {
  fn from(data: DateTypeOptionPB) -> Self {
    Self {
      date_format: data.date_format.into(),
      time_format: data.time_format.into(),
      timezone_id: data.timezone_id,
      field_type: data.field_type,
    }
  }
}

#[derive(Clone, Debug, Copy, EnumIter, ProtoBuf_Enum)]
pub enum DateFormatPB {
  Local = 0,
  US = 1,
  ISO = 2,
  Friendly = 3,
  DayMonthYear = 4,
}
impl std::default::Default for DateFormatPB {
  fn default() -> Self {
    DateFormatPB::Friendly
  }
}

impl From<DateFormatPB> for DateFormat {
  fn from(data: DateFormatPB) -> Self {
    match data {
      DateFormatPB::Local => DateFormat::Local,
      DateFormatPB::US => DateFormat::US,
      DateFormatPB::ISO => DateFormat::ISO,
      DateFormatPB::Friendly => DateFormat::Friendly,
      DateFormatPB::DayMonthYear => DateFormat::DayMonthYear,
    }
  }
}

impl From<DateFormat> for DateFormatPB {
  fn from(data: DateFormat) -> Self {
    match data {
      DateFormat::Local => DateFormatPB::Local,
      DateFormat::US => DateFormatPB::US,
      DateFormat::ISO => DateFormatPB::ISO,
      DateFormat::Friendly => DateFormatPB::Friendly,
      DateFormat::DayMonthYear => DateFormatPB::DayMonthYear,
    }
  }
}

#[derive(Clone, Copy, PartialEq, Eq, EnumIter, Debug, Hash, ProtoBuf_Enum)]
pub enum TimeFormatPB {
  TwelveHour = 0,
  TwentyFourHour = 1,
}

impl std::default::Default for TimeFormatPB {
  fn default() -> Self {
    TimeFormatPB::TwentyFourHour
  }
}

impl From<TimeFormatPB> for TimeFormat {
  fn from(data: TimeFormatPB) -> Self {
    match data {
      TimeFormatPB::TwelveHour => TimeFormat::TwelveHour,
      TimeFormatPB::TwentyFourHour => TimeFormat::TwentyFourHour,
    }
  }
}

impl From<TimeFormat> for TimeFormatPB {
  fn from(data: TimeFormat) -> Self {
    match data {
      TimeFormat::TwelveHour => TimeFormatPB::TwelveHour,
      TimeFormat::TwentyFourHour => TimeFormatPB::TwentyFourHour,
    }
  }
}
