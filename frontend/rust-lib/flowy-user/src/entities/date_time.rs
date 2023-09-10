use serde::{Deserialize, Serialize};

use flowy_derive::ProtoBuf_Enum;

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Debug, Clone, Default, Copy)]
pub enum DateFormatPB {
  Locally = 0,
  US = 1,
  ISO = 2,
  #[default]
  Friendly = 3,
  DayMonthYear = 4,
}

impl std::convert::From<i64> for DateFormatPB {
  fn from(value: i64) -> Self {
    match value {
      0 => DateFormatPB::Locally,
      1 => DateFormatPB::US,
      2 => DateFormatPB::ISO,
      3 => DateFormatPB::Friendly,
      4 => DateFormatPB::DayMonthYear,
      _ => {
        tracing::error!("Unsupported date format, fallback to friendly");
        DateFormatPB::Friendly
      },
    }
  }
}

impl DateFormatPB {
  pub fn value(&self) -> i64 {
    *self as i64
  }
  // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
  pub fn format_str(&self) -> &'static str {
    match self {
      DateFormatPB::Locally => "%m/%d/%Y",
      DateFormatPB::US => "%Y/%m/%d",
      DateFormatPB::ISO => "%Y-%m-%d",
      DateFormatPB::Friendly => "%b %d, %Y",
      DateFormatPB::DayMonthYear => "%d/%m/%Y",
    }
  }
}

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Debug, Clone, Default, Copy)]
pub enum TimeFormatPB {
  TwelveHour = 0,
  #[default]
  TwentyFourHour = 1,
}

impl std::convert::From<i64> for TimeFormatPB {
  fn from(value: i64) -> Self {
    match value {
      0 => TimeFormatPB::TwelveHour,
      1 => TimeFormatPB::TwentyFourHour,
      _ => {
        tracing::error!("Unsupported time format, fallback to TwentyFourHour");
        TimeFormatPB::TwentyFourHour
      },
    }
  }
}

impl TimeFormatPB {
  pub fn value(&self) -> i64 {
    *self as i64
  }

  // https://docs.rs/chrono/0.4.19/chrono/format/strftime/index.html
  pub fn format_str(&self) -> &'static str {
    match self {
      TimeFormatPB::TwelveHour => "%I:%M %p",
      TimeFormatPB::TwentyFourHour => "%R",
    }
  }
}
