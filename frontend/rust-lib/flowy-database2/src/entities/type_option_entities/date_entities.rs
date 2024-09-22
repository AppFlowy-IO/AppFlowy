#![allow(clippy::upper_case_acronyms)]

use collab_database::fields::time_type_option::{
  DateCellData, DateFormat, DateTypeOption, TimeFormat,
};
use strum_macros::EnumIter;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

use crate::entities::CellIdPB;

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateCellDataPB {
  #[pb(index = 1)]
  pub date: String,

  #[pb(index = 2)]
  pub time: String,

  #[pb(index = 3)]
  pub timestamp: i64,

  #[pb(index = 4)]
  pub end_date: String,

  #[pb(index = 5)]
  pub end_time: String,

  #[pb(index = 6)]
  pub end_timestamp: i64,

  #[pb(index = 7)]
  pub include_time: bool,

  #[pb(index = 8)]
  pub is_range: bool,

  #[pb(index = 9)]
  pub reminder_id: String,
}
impl From<&DateCellDataPB> for DateCellData {
  fn from(data: &DateCellDataPB) -> Self {
    Self {
      timestamp: Some(data.timestamp),
      end_timestamp: Some(data.end_timestamp),
      include_time: data.include_time,
      is_range: data.is_range,
      reminder_id: data.reminder_id.to_owned(),
    }
  }
}

#[derive(Clone, Debug, Default, ProtoBuf)]
pub struct DateCellChangesetPB {
  #[pb(index = 1)]
  pub cell_id: CellIdPB,

  #[pb(index = 2, one_of)]
  pub date: Option<i64>,

  #[pb(index = 3, one_of)]
  pub time: Option<String>,

  #[pb(index = 4, one_of)]
  pub end_date: Option<i64>,

  #[pb(index = 5, one_of)]
  pub end_time: Option<String>,

  #[pb(index = 6, one_of)]
  pub include_time: Option<bool>,

  #[pb(index = 7, one_of)]
  pub is_range: Option<bool>,

  #[pb(index = 8, one_of)]
  pub clear_flag: Option<bool>,

  #[pb(index = 9, one_of)]
  pub reminder_id: Option<String>,
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
}

impl From<DateTypeOption> for DateTypeOptionPB {
  fn from(data: DateTypeOption) -> Self {
    Self {
      date_format: data.date_format.into(),
      time_format: data.time_format.into(),
      timezone_id: data.timezone_id,
    }
  }
}

impl From<DateTypeOptionPB> for DateTypeOption {
  fn from(data: DateTypeOptionPB) -> Self {
    Self {
      date_format: data.date_format.into(),
      time_format: data.time_format.into(),
      timezone_id: data.timezone_id,
    }
  }
}

#[derive(Clone, Debug, Copy, ProtoBuf_Enum, Default)]
pub enum DateFormatPB {
  Local = 0,
  US = 1,
  ISO = 2,
  #[default]
  Friendly = 3,
  DayMonthYear = 4,
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

#[derive(Clone, Copy, PartialEq, Eq, EnumIter, Debug, Hash, ProtoBuf_Enum, Default)]
pub enum TimeFormatPB {
  TwelveHour = 0,
  #[default]
  TwentyFourHour = 1,
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
